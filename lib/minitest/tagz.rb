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
      def apply_tags(namespace, obj, pending_tags = nil)
        if pending_tags
          tags["#{namespace}::#{obj}"] += pending_tags
        elsif @pending_tags
          # TODO
          tags["#{namespace}::#{obj}"] += @pending_tags
          @pending_tags = nil
        end
      end

      def dump_tags
        if @pending_tags
          duped = @pending_tags.dup
          @pending_tags = nil
          duped
        end
      end

      def record_blanket_tags
        if @pending_tags
          # TODO
          self.blanket_tags = @pending_tags
          @pending_tags = nil
        end
      end

      def apply_blanket_tags(namespace, obj)
        unless blanket_tags.empty?
          tags["#{namespace}::#{obj}"] += @blanket_tags
        end
      end

      # Select all the testables with matching tags
      def filter(namespace, enum)
        enum.select {|obj| has_matching_tags?(namespace, obj)}
      end

      def reset_blanket_tags
        @blanket_tags = []
      end

      def chosen_tags
        @chosen_tags ||= Set.new
      end

      def tags
        @tags ||= Hash.new([])
      end

      private

      # Check if object has matching tags
      def has_matching_tags?(namespace, obj)
        obj_tags = tags["#{namespace}::#{obj}"] || []
        chosen_tags.all? { |tag| obj_tags.include?(tag) }
      end

      def blanket_tags
        @blanket_tags ||= reset_blanket_tags
      end

      def blanket_tags=(arg)
        @blanket_tags = arg
      end
    end
  end
end
