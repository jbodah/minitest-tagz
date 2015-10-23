require 'spec_helper'

module Minitest
  module Tagz
    class MinitestSpecExample < Minitest::Spec
      tag :login
      it 'tests things with the :login tag' do
        skip
        true
      end

      tag :login, :fast
      it 'tests things with the :login and :fast tags' do
        skip
        true
      end

      it 'tests things with no tags' do
        skip
        true
      end
    end

    class MinitestSpecExampleWithDescribe < Minitest::Spec
      tag :feature
      describe 'a tagged describe' do
        it 'tests the first thing inside' do
          skip
          true
        end

        it 'tests the second thing inside' do
          skip
          true
        end

        describe 'a nested describe' do
          it 'tests things inside' do
            skip
            true
          end
        end
      end

      describe 'an untagged describe' do
        it 'tests the first thing inside' do
          skip
          true
        end
      end

      it 'tests something outside a describe block' do
        skip
        true
      end
    end

    class MinitestTestExample < Minitest::Test
      tag :login, :fast
      def test_with_login_and_fast_tags
        skip
        assert true
      end

      tag :login
      def test_with_login_tag
        skip
        assert true
      end

      def test_without_login_tag
        skip
        assert true
      end
    end

    class MinitestSpecExampleWithSameNameButWithoutTags < Minitest::Spec
      it 'tests things with the :login tag' do
        skip
        true
      end
    end

    class MinitestAdapterSpec < Minitest::Spec
      after do
        # Reset tags
        Tagz.choose_tags
      end

      describe 'Minitest::Test' do
        describe 'one tag specified' do
          before do
            Tagz.choose_tags(:login)
          end

          it 'runs tests with that tag' do
            assert MinitestTestExample.runnable_methods.include?('test_with_login_tag'),
              "expected tests with tag to be run"
            assert MinitestTestExample.runnable_methods.include?('test_with_login_and_fast_tags'),
              "expected tests with tag and more to be run"
          end

          it 'does not run tests without that tag' do
            refute MinitestTestExample.runnable_methods.include?('test_without_login_tag'),
              "didn't expect test without tag to be run"
          end
        end

        describe 'multiple tags specified' do
          before do
            Tagz.choose_tags(:login, :fast)
          end

          it 'runs tests that have all the tags' do
            assert MinitestTestExample.runnable_methods.include?('test_with_login_and_fast_tags'),
              "expected test with all tags to be run"
          end

          it 'does not run tests with some of the tags' do
            refute MinitestTestExample.runnable_methods.include?('test_with_login_tag'),
              "didn't expect test with only some matching tags to be run"
          end

          it 'does not run tests with none of the tags' do
            refute MinitestTestExample.runnable_methods.include?('test_without_login_tag'),
              "didn't expect test with no matching tags to be run"
          end
        end

        describe 'no tags specified' do
          it 'runs all of the tests' do
            assert MinitestTestExample.runnable_methods.include?('test_with_login_tag'), 'expected all tests to be run'
            assert MinitestTestExample.runnable_methods.include?('test_with_login_and_fast_tags'), 'expected all tests to be run'
            assert MinitestTestExample.runnable_methods.include?('test_without_login_tag'), 'expected all tests to be run'
          end
        end
      end

      describe 'Minitest::Spec' do
        describe 'top level tests' do
          describe 'with multiple tags specified' do
            before do
              Tagz.choose_tags(:login, :fast)
            end

            it 'runs tests with all of the tags' do
              assert MinitestSpecExample.runnable_methods.include?('test_0002_tests things with the :login and :fast tags')
            end

            it 'does not run tests with only some of the tags' do
              refute MinitestSpecExample.runnable_methods.include?('test_0001_tests things with the :login tag')
            end

            it 'does not run tests with none of the tags' do
              refute MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags'),
                "didn't expect test with none of the tags to be run"
            end
          end

          describe 'with a single tag specified' do
            before do
              Tagz.choose_tags(:login)
            end

            it 'runs tests with that tag' do
              assert MinitestSpecExample.runnable_methods.include?('test_0001_tests things with the :login tag')
              assert MinitestSpecExample.runnable_methods.include?('test_0002_tests things with the :login and :fast tags')
            end

            it 'does not run tests without that tag' do
              refute MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags'),
                "shouldn't run spec tests without that tag"
            end
          end

          describe 'without a tag specified' do
            it 'runs all tests' do
              assert MinitestSpecExample.runnable_methods.include?('test_0001_tests things with the :login tag')
              assert MinitestSpecExample.runnable_methods.include?('test_0002_tests things with the :login and :fast tags')
              assert MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags')
            end
          end
        end

        describe 'a suite with similarly named tests' do
          before do
            Tagz.choose_tags(:login)
          end

          it "does not run tests with similar names that aren't tagged" do
            refute MinitestSpecExampleWithSameNameButWithoutTags.runnable_methods.include?('test_0001_tests things with the :login tag'),
              "it shouldn't run spec tests with similar names that aren't tagged"
          end
        end

        describe 'describe blocks' do
          describe 'with a tag specified' do
            before do
              Tagz.choose_tags(:feature)
            end

            it 'runs top level tests in the describe block' do
              describe_block = MinitestSpecExampleWithDescribe.children.find {|c| c.name == 'a tagged describe'}
              assert describe_block.runnable_methods.include?('test_0001_tests the first thing inside')
              assert describe_block.runnable_methods.include?('test_0002_tests the second thing inside'),
                "expected top level test to be run"
            end

            it 'runs tests of nested describe blocks' do
              describe_block = MinitestSpecExampleWithDescribe.children.find {|c| c.name == 'a tagged describe'}
              nested_describe_block = describe_block.children.find {|c| c.name == 'a tagged describe::a nested describe'}
              assert nested_describe_block.runnable_methods.include?('test_0001_tests things inside')
            end

            it 'does not run top level tests without that tag' do
              refute MinitestSpecExampleWithDescribe.runnable_methods.include?('test_0001_tests something outside a describe block'),
                "didn't expect top level test without that tag to be run"
            end

            it 'does not run tests of other describe blocks without that tag' do
              describe_block = MinitestSpecExampleWithDescribe.children.find {|c| c.name == 'an untagged describe'}
              refute describe_block.runnable_methods.include?('test_0001_tests the first thing inside'),
                "dind't expect test from other describe block to be run"
            end
          end
        end
      end
    end

    class ShouldaContextSpec < Minitest::Spec
      include ShouldaContextLoadable

      before do
        @serialized = Minitest::Tagz::RunnerStrategy.serialize(ShouldaContextSpec, name)
      end

      context 'tags on should blocks' do
        should 'not tag this test' do
          assert_equal nil, Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
        end

        tag :shoulda_tag
        should 'tag this test' do
          assert_equal [:shoulda_tag], Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
        end

        should 'not tag this test either' do
          assert_equal nil, Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
        end

        context 'tags on nested should blocks' do
          tag :another_should_tag
          should 'tag this test' do
            assert_equal [:another_should_tag], Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
          end
        end
      end

      tag :context_tag
      context 'tags on context blocks' do
        should 'tag this test' do
          assert_equal [:context_tag], Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
        end

        should 'also tag this test' do
          assert_equal [:context_tag], Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
        end
      end

      tag :nested_context_tag
      context 'tags on nested context blocks' do
        context 'a nested context block' do
          should 'tag this test' do
            assert_equal [:nested_context_tag], Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
          end

          should 'also tag this test' do
            assert_equal [:nested_context_tag], Minitest::Tagz::RunnerStrategy.tag_map[@serialized]
          end
        end
      end
    end
  end
end
