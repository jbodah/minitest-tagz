module Minitest
  module Tagz
    module MinitestAdapter
      module Base
        def tag(*tags)
          Tagz.declare_tags(*tags)
        end

        def method_added(name)
          return unless name[/^test_/]
          Tagz.apply_tags(name)
        end

        def runnable_methods
          Tagz.filter(super)
        end
      end
    end
  end
end

if defined?(Minitest)
  ::Minitest::Test.singleton_class.prepend(Minitest::Tagz::MinitestAdapter::Base)
end
