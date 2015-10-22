module Minitest
  module Tagz
    module MinitestAdapter
      module Base
        def tag(*tags)
          Tagz.declare_tags(*tags)
        end

        def runnable_methods
          Tagz.filter(self, super)
        end

        def method_added(name)
          return unless name[/^test_/]
          Tagz.apply_tags(self, name)
          super
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

if defined?(ShouldaContextLoadable)
  module Minitest
    module Tagz
      module ShouldaAdapter
        def should(name, opts = {}, &block)
          tags = Tagz.dump_tags
          super name, opts, &block
          self.shoulds.last[:tagz] = tags if tags
        end

        def create_test_from_should_hash(should)
          if should[:tagz]
            test_name = super.to_s
            minitest_parent = self.parent
            until minitest_parent.is_a?(Class)
              minitest_parent = minitest_parent.parent
            end
            Tagz.apply_tags(minitest_parent, test_name, should[:tagz])
          else
            super
          end
        end
      end
    end
  end

  Shoulda::Context::Context.prepend(Minitest::Tagz::ShouldaAdapter)
end
