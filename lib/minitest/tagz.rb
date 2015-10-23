require 'minitest/tagz/version'
require 'state_machine'

module Minitest
  module Tagz
    module MinitestRunnerStrategy
      class << self
        def serialize(owner, test_name)
          "#{owner} >> #{test_name}"
        end

        def patch
          ::Minitest::Test.singleton_class.class_eval do
            attr_reader :tag_map

            old_runnable_methods = instance_method(:runnable_methods)
            define_method :runnable_methods do
              if Tagz.chosen_tags && Tagz.chosen_tags.any?
                all_runnables = old_runnable_methods.bind(self).call
                all_runnables.select do |r|
                  next false unless MinitestRunnerStrategy.tag_map[MinitestRunnerStrategy.serialize(self, r)]
                  (Tagz.chosen_tags - MinitestRunnerStrategy.tag_map[MinitestRunnerStrategy.serialize(self, r)]).empty?
                end
              else
                old_runnable_methods.bind(self).call
              end
            end
          end
        end

        def tag_map
          @tag_map ||= {}
        end
      end
    end

    MinitestRunnerStrategy.patch
    RunnerStrategy = MinitestRunnerStrategy

    module BaseMixin
      def tag(*tags)
        Tagz.declare_tag_assignment(self, tags)
      end
    end

    class TaggerFactory
      def self.create_tagger(owner, pending_tags)
        patchers = [MinitestPatcher]
        patchers << ShouldaPatcher if owner.ancestors.include?(ShouldaContextLoadable)
        Tagger.new(patchers, owner, pending_tags)
      end
    end

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

    module ShouldaPatcher
      if defined?(::Shoulda::Context::Context)
        ::Shoulda::Context::Context.include(Tagz::BaseMixin)
      end

      # yuck
      old_create_test_from_should_hash = Shoulda::Context::Context.instance_method(:create_test_from_should_hash)
      Shoulda::Context::Context.class_eval do
        define_method(:create_test_from_should_hash) do |shd|
          if shd[:tagz]
            test_name = old_create_test_from_should_hash.bind(self).call(shd).to_s
            minitest_parent = self.parent
            until minitest_parent.is_a?(Class)
              minitest_parent = minitest_parent.parent
            end
            Tagz::RunnerStrategy.tag_map[Tagz::RunnerStrategy.serialize(minitest_parent, test_name)] = shd[:tagz]
          else
            old_create_test_from_should_hash.bind(self).call(shd)
          end
        end
      end

      class << self
        def patch(state_machine)
          patch_context(state_machine)
          patch_should(state_machine)
        end

        def unpatch
          unpatch_context
          unpatch_should
        end

        private

        def patch_should(state_machine)
          @old_should = old_should = Shoulda::Context::Context.instance_method(:should)
          Shoulda::Context::Context.class_eval do
            define_method(:should) do |*args, &block|
              state_machine.handle_initial_test_definition do
                old_should.bind(self).call(*args, &block)
                self.shoulds.last[:tagz] = state_machine.pending_tags if state_machine.pending_tags
              end
            end
          end
        end

        def patch_context(state_machine)
          @old_context = old_context = Shoulda::Context::ClassMethods.instance_method(:context)
          Shoulda::Context::ClassMethods.class_eval do
            define_method(:context) do |name, *args, &block|
              state_machine.handle_initial_test_definition do
                old_context.bind(self).call(name, *args, &block)
              end
            end
          end
        end

        def unpatch_should
          old_should = @old_should
          Shoulda::Context::Context.class_eval { define_method(:should, old_should) }
        end

        def unpatch_context
          old_context = @old_context
          Shoulda::Context::ClassMethods.class_eval { define_method(:context, old_context) }
        end
      end
    end

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
          @old_describe = old_describe = Minitest::Spec.method(:describe)
          Minitest::Spec.class_eval do
            define_singleton_method(:describe) do |*args, &block|
              state_machine.handle_initial_test_definition do
                old_describe.unbind.bind(self).call(*args, &block)
              end
            end
          end
        end

        def unpatch_minitest_spec
          Minitest::Spec.define_singleton_method(:describe, @old_describe)
        end
      end
    end

    class << self
      attr_accessor :chosen_tags

      # Create a master TagSet that you wish to test. You only
      # want to run tests with tags in this set
      # @param [Enumerable<Symbol>] tags - a list of tags you want to test
      def choose_tags(*tags)
        @chosen_tags = tags
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
