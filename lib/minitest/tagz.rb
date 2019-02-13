require 'minitest'
require 'minitest/tagz/minitest_patch'
require 'minitest/tagz/minitest_test_patch'
require 'minitest/tagz/tagger'
require 'minitest/tagz/patcher'
require 'minitest/tagz/version'

module Minitest
  module Tagz
    class << self
      attr_accessor :run_all_if_no_match, :log_if_no_match

      alias :run_all_if_no_match? :run_all_if_no_match
      alias :log_if_no_match? :log_if_no_match

      # Create a master TagSet that you wish to test. You only
      # want to run tests with tags in this set
      #
      # @param [Enumerable<Symbol>] tags - a list of tags you want to test
      # @param [Boolean] run_all_if_no_match - will run all tests if no tests are found with the tag
      # @param [Boolean] log_if_no_match - puts if no match specs found
      def choose_tags(*tags, log_if_no_match: false, run_all_if_no_match: false)
        @chosen_tags = tags.map(&:to_s)
        @run_all_if_no_match = run_all_if_no_match
        @log_if_no_match = log_if_no_match
      end

      # @private
      def chosen_tags
        @chosen_tags ||= []
      end

      # @private
      def positive_tags
        chosen_tags.reject {|t| t.is_a?(String) && t[/^-/]}
      end

      # @private
      def negative_tags
        chosen_tags.select {|t| t.is_a?(String) && t[/^-/]}.map {|t| t[1..-1]}
      end

      # @private
      def serialize(owner, test_name)
        "#{owner} >> #{test_name}"
      end

      # @private
      def tag_map
        @tag_map ||= {}
      end
    end
  end
end

Minitest.singleton_class.prepend(Minitest::Tagz::MinitestPatch)
Minitest::Test.extend(Minitest::Tagz::MinitestTestPatch)
