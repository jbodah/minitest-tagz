require 'minitest/tagz/version'
require 'state_machine'

module Minitest
  module Tagz
    # The strategy for patching the Minitest run time
    module MinitestRunnerStrategy
      class << self
        def serialize(owner, test_name)
          "#{owner} >> #{test_name}"
        end

        module RunnableMethodsFilter
          def runnable_methods
            all_runnables = super
            if Tagz.chosen_tags && Tagz.chosen_tags.any?
              all_runnables.select do |r|
                serialized = MinitestRunnerStrategy.serialize(self, r)
                tags_on_runnable = MinitestRunnerStrategy.tag_map[serialized] 
                next false unless tags_on_runnable
                (Tagz.chosen_tags - tags_on_runnable).empty?
              end
            else
              all_runnables
            end
          end
        end

        module RunPatch
          def run(*args)
            # Check for no match and don't filter runnable methods if there would be no match
            if Tagz.run_all_if_no_match?
              run_map = Runnable.runnables.reduce({}) {|memo, r| memo[r] = r.runnable_methods; memo}
              should_skip_filter = run_map.all? do |ctxt, methods| 
                methods.all? do |m|
                  serialized = MinitestRunnerStrategy.serialize(ctxt, m)
                  tags = MinitestRunnerStrategy.tag_map[serialized]
                  tags.nil? || tags.empty?
                end
              end
              if should_skip_filter
                puts "Couldn't find any runnables with the given tag, running all runnables" if Tagz.log_if_no_match?
                return super 
              end
            end

            ::Minitest::Test.singleton_class.class_eval { prepend(RunnableMethodsFilter) }
            super
          end
        end

        def patch
          ::Minitest.singleton_class.class_eval { prepend(RunPatch) }
        end

        def tag_map
          @tag_map ||= {}
        end
      end
    end

    # Patch the Minitest runtime to hook into Tagz
    MinitestRunnerStrategy.patch

    # Alias
    RunnerStrategy = MinitestRunnerStrategy

    # Was more useful when I was trying to add
    # shoulda-context support
    module BaseMixin
      def tag(*tags)
        Tagz.declare_tag_assignment(self, tags)
      end
    end

    # Was more useful when I was trying to add
    # shoulda-context support
    class TaggerFactory
      def self.create_tagger(owner, pending_tags)
        patchers = [MinitestPatcher]
        Tagger.new(patchers, owner, pending_tags)
      end
    end

    # Represents the individual instance of a `tag` call
    # It is essentially a state machine that works with the
    # patcher to patch and unpatch Minitest properly
    class Tagger
      state_machine :state, initial: :awaiting_tag_declaration do
        after_transition any => :awaiting_test_definition, do: :patch_test_definitions
        after_transition any => :finished, do: :unpatch_test_definitions

        event :tags_declared do
          transition :awaiting_tag_declaration => :awaiting_test_definition
        end

        event :initial_test_definition_encountered do
          transition :awaiting_test_definition => :applying_tags
        end

        event :finished_applying_tags do
          transition :applying_tags => :finished
        end
      end

      attr_reader :patchers, :owner, :pending_tags

      def initialize(patchers, owner, pending_tags)
        @patchers = patchers
        @owner = owner
        @pending_tags = pending_tags
        super()
      end

      def patch_test_definitions
        @patchers.each {|p| p.patch(self)}
      end

      def unpatch_test_definitions
        @patchers.each(&:unpatch)
      end

      def handle_initial_test_definition
        is_initial = awaiting_test_definition?
        initial_test_definition_encountered if is_initial
        res = yield
        finished_applying_tags if is_initial
        res
      end
    end

    # Patches Minitest to track tags
    module MinitestPatcher
      ::Minitest::Test.extend(Tagz::BaseMixin)

      class << self
        def patch(state_machine)
          patch_minitest_test(state_machine)
          patch_minitest_spec(state_machine)
        end

        def unpatch
          unpatch_minitest_test
          unpatch_minitest_spec
        end

        private

        def patch_minitest_test(state_machine)
          @old_method_added = old_method_added = Minitest::Test.method(:method_added)
          Minitest::Test.class_eval do
            define_singleton_method(:method_added) do |name|
              if name[/^test_/]
                state_machine.handle_initial_test_definition do
                  Tagz::RunnerStrategy.tag_map ||= {}
                  Tagz::RunnerStrategy.tag_map[Tagz::RunnerStrategy.serialize(self, name)] ||= []
                  Tagz::RunnerStrategy.tag_map[Tagz::RunnerStrategy.serialize(self, name)] += state_machine.pending_tags
                  old_method_added.call(name)
                end
              else
                old_method_added.call(name)
              end
            end
          end
        end

        def unpatch_minitest_test
          Minitest::Test.define_singleton_method(:method_added, @old_method_added)
        end

        def patch_minitest_spec(state_machine)
          @old_describe = old_describe = Kernel.instance_method(:describe)
          Kernel.module_eval do
            define_method(:describe) do |*args, &block|
              state_machine.handle_initial_test_definition do
                old_describe.bind(self).call(*args, &block)
              end
            end
          end
        end

        def unpatch_minitest_spec
          old_describe = @old_describe
          Kernel.module_eval do
            define_method(:describe, old_describe)
          end
        end
      end
    end

    # Main extensions to Minitest
    class << self
      attr_accessor :chosen_tags, :run_all_if_no_match, :log_if_no_match

      alias :run_all_if_no_match? :run_all_if_no_match
      alias :log_if_no_match? :log_if_no_match

      # Create a master TagSet that you wish to test. You only
      # want to run tests with tags in this set
      # @param [Enumerable<Symbol>] tags - a list of tags you want to test
      # @param [Boolean] run_all_if_no_match - will run all tests if no tests are found with the tag
      # @param [Boolean] log_if_no_match - puts if no match specs found
      def choose_tags(*tags, log_if_no_match: false, run_all_if_no_match: false)
        @chosen_tags = tags.map(&:to_sym)
        @run_all_if_no_match = run_all_if_no_match
        @log_if_no_match = log_if_no_match
      end

      def declare_tag_assignment(owner, pending_tags)
        tag_machine = TaggerFactory.create_tagger(owner, pending_tags)
        tag_machine.tags_declared
        # TODO add debugging tip about this
        tag_machine
      end
    end
  end
end
