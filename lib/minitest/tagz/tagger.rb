module Minitest
  module Tagz
    # Represents the individual instance of a `tag` call
    # It is essentially a state machine that works with the
    # patcher to patch and unpatch Minitest properly
    class Tagger
      attr_reader :patchers, :owner, :pending_tags

      def initialize(patchers, owner, pending_tags)
        @patchers = patchers
        @owner = owner
        @pending_tags = pending_tags.map(&:to_s)
      end

      def tags_declared!
        patch_test_definitions
        @awaiting_initial_test_definition = true
      end

      def handle_initial_test_definition!
        is_initial = @awaiting_initial_test_definition
        @awaiting_initial_test_definition = false if is_initial
        res = yield
        unpatch_test_definitions if is_initial
        res
      end

      private

      def patch_test_definitions
        @patchers.each {|p| p.patch(self)}
      end

      def unpatch_test_definitions
        @patchers.each(&:unpatch)
      end
    end
  end
end
