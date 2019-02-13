# Responsible for patching/unpatching Minitest. When `tag` is called we patch Minitest and
module Minitest
  module Tagz
    module Patcher
      class << self
        def patch(state_machine)
          patch_minitest_test(state_machine)
          patch_minitest_spec(state_machine) if spec_included?
        end

        def unpatch
          unpatch_minitest_test
          unpatch_minitest_spec if spec_included?
        end

        private

        def spec_included?
          !defined?(::Minitest::Spec).nil?
        end

        def patch_minitest_test(state_machine)
          Minitest::Test.class_eval do
            self.singleton_class.class_eval do
              alias :old_method_added :method_added

              define_method(:method_added) do |name|
                if name[/^test_/]
                  state_machine.handle_initial_test_definition! do
                    Tagz.tag_map ||= {}
                    Tagz.tag_map[Tagz.serialize(self, name)] ||= []
                    Tagz.tag_map[Tagz.serialize(self, name)] += state_machine.pending_tags
                    old_method_added(name)
                  end
                else
                  old_method_added(name)
                end
              end
            end
          end
        end

        def unpatch_minitest_test
          Minitest::Test.class_eval do
            self.singleton_class.class_eval do
              undef_method :method_added
              alias :method_added :old_method_added
            end
          end
        end

        def patch_minitest_spec(state_machine)
          Kernel.module_eval do
            alias :old_describe :describe

            define_method(:describe) do |*args, &block|
              state_machine.handle_initial_test_definition! do
                old_describe(*args, &block)
              end
            end
          end
        end

        def unpatch_minitest_spec
          Kernel.module_eval do
            undef_method :describe
            alias :describe :old_describe
          end
        end
      end
    end
  end
end
