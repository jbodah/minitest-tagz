require 'minitest/tagz/version'
require 'minitest/tagz/minitest_adapter'

module Minitest
  module Tagz
    class << self
      # Pick the tags you want to test
      def choose_tags(*tags)
        @chosen_tags = tags.map(&:to_sym).compact.to_set
      end

      # Create a tag on a test
      def declare_tags(*pending_tags)
        @pending_tags = pending_tags
      end

      # Record the given tags with the object
      def apply_tags(obj)
        if @pending_tags
          tags[obj.to_s] = @pending_tags
          @pending_tags = nil
        end
      end

      # Select all the testables with matching tags
      def filter(enum)
        enum.select {|obj| has_matching_tags?(obj)}
      end

      private

      # Check if object has matching tags
      def has_matching_tags?(obj)
        obj_tags = tags[obj.to_s] || []
        chosen_tags.all? { |tag| obj_tags.include?(tag) }
      end

      def chosen_tags
        @chosen_tags ||= Set.new
      end

      def tags
        @tags ||= {}
      end
    end
  end
end
