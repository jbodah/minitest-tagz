module Minitest
  module Tagz
    module MinitestAdapter
      module Base
        def tag(*tags)
          Tagz.declare_tags(*tags)
        end

        def method_added(name)
          return unless name[/^test_/]
          Tagz.apply_tags(self, name)
        end

        def runnable_methods
          Tagz.filter(self, super)
        end
      end

      module Spec
        def describe(*args, &block)
          Tagz.record_blanket_tags
          super
          apply_blanket_tags_recursively
          Tagz.reset_blanket_tags
        end

        def apply_blanket_tags_recursively
          test_methods_in_describe = instance_methods.select {|m| m[/^test/]}
          test_methods_in_describe.each do |runnable|
            Tagz.apply_blanket_tags(self, runnable)
          end

          children.each do |child|
            child.apply_blanket_tags_recursively
          end
        end
      end
    end
  end
end

if defined?(Minitest)
  ::Minitest::Test.singleton_class.prepend(Minitest::Tagz::MinitestAdapter::Base)
  if defined?(Minitest::Spec)
    ::Minitest::Spec.singleton_class.prepend(Minitest::Tagz::MinitestAdapter::Spec)
  end
end
