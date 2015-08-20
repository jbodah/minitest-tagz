require "minitest/tagz/version"

module Minitest
  module Tagz
    class << self
      def choose_tags(*tags)
        @chosen_tags = tags.compact
      end

      def has_matching_tags?(tags)
        tags ||= []
        chosen_tags.all? { |tag| tags.include?(tag) }
      end

      def chosen_tags
        @chosen_tags ||= []
      end
    end

    module MinitestAdapter
      def tag(*pending_tags)
        @pending_tags ||= pending_tags
      end

      def method_added(name)
        return unless name[/^test_/]
        tags[name.to_s] = @pending_tags
        @pending_tags = nil
      end

      def tags
        @tags ||= {}
      end

      def runnable_methods
        runnables = super
        runnables.select do |runnable|
          Minitest::Tagz.has_matching_tags?(tags[runnable])
        end
      end
    end

    def self.patch_minitest
      ::Minitest::Test.singleton_class.prepend(MinitestAdapter)
    end

    patch_minitest
  end
end
