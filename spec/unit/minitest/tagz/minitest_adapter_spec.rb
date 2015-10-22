require 'spec_helper'

module Minitest
  module Tagz
    class MinitestSpecExample < Minitest::Spec
      tag :login
      it 'tests things with the :login tag' do
        true
      end

      tag :login, :fast
      it 'tests things with the :login and :fast tags' do
        true
      end

      it 'tests things with no tags' do
        true
      end
    end

    class MinitestSpecExampleWithDescribe < Minitest::Spec
      tag :feature
      describe 'a tagged describe' do
        it 'tests the first thing inside' do
          true
        end

        it 'tests the second thing inside' do
          true
        end

        describe 'a nested describe' do
          it 'tests things inside' do
            true
          end
        end
      end

      describe 'an untagged describe' do
        it 'tests the first thing inside' do
          true
        end
      end

      it 'tests something outside a describe block' do
        true
      end
    end

    class MinitestTestExample < Minitest::Test
      tag :login, :fast
      def test_with_login_and_fast_tags
        assert true
      end

      tag :login
      def test_with_login_tag
        assert true
      end

      def test_without_login_tag
        assert true
      end
    end

    class MinitestSpecExampleWithSameNameButWithoutTags < Minitest::Spec
      it 'tests things with the :login tag' do
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
            assert MinitestTestExample.runnable_methods.include?('test_with_login_tag')
            assert MinitestTestExample.runnable_methods.include?('test_with_login_and_fast_tags')
          end

          it 'does not run tests without that tag' do
            refute MinitestTestExample.runnable_methods.include?('test_without_login_tag')
          end
        end

        describe 'multiple tags specified' do
          before do
            Tagz.choose_tags(:login, :fast)
          end

          it 'runs tests that have all the tags' do
            assert MinitestTestExample.runnable_methods.include?('test_with_login_and_fast_tags')
          end

          it 'does not run tests with some of the tags' do
            refute MinitestTestExample.runnable_methods.include?('test_with_login_tag')
          end

          it 'does not run tests with none of the tags' do
            refute MinitestTestExample.runnable_methods.include?('test_without_login_tag')
          end
        end

        describe 'no tags specified' do
          it 'runs all of the tests' do
            assert MinitestTestExample.runnable_methods.include?('test_with_login_tag')
            assert MinitestTestExample.runnable_methods.include?('test_with_login_and_fast_tags')
            assert MinitestTestExample.runnable_methods.include?('test_without_login_tag')
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
              refute MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags')
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
              refute MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags')
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
            refute MinitestSpecExampleWithSameNameButWithoutTags.runnable_methods.include?('test_0001_tests things with the :login tag')
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
              assert describe_block.runnable_methods.include?('test_0002_tests the second thing inside')
            end

            it 'runs tests of nested describe blocks' do
              describe_block = MinitestSpecExampleWithDescribe.children.find {|c| c.name == 'a tagged describe'}
              nested_describe_block = describe_block.children.find {|c| c.name == 'a tagged describe::a nested describe'}
              assert nested_describe_block.runnable_methods.include?('test_0001_tests things inside')
            end

            it 'does not run top level tests without that tag' do
              refute MinitestSpecExampleWithDescribe.runnable_methods.include?('test_0001_tests something outside a describe block')
            end

            it 'does not run tests of other describe blocks without that tag' do
              describe_block = MinitestSpecExampleWithDescribe.children.find {|c| c.name == 'an untagged describe'}
              refute describe_block.runnable_methods.include?('test_0001_tests the first thing inside')
            end
          end
        end
      end
    end

    class ShouldaContextSpec < Minitest::Spec
      include ShouldaContextLoadable

      context 'tags on should blocks' do
        should 'not tag this test' do
          refute Tagz.tags.include?(self.class.name + '::' + name)
        end

        tag :shoulda_tag
        should 'tag this test' do
          assert Tagz.tags.include?(self.class.name + '::' + name)
        end

        should 'not tag this test either' do
          refute Tagz.tags.include?(self.class.name + '::' + name)
        end

        context 'tags on nested should blocks' do
          tag :another_should_tag
          should 'tag this test' do
            assert Tagz.tags.include?(self.class.name + '::' + name)
          end
        end
      end

      tag :context_tag
      context 'tags on context blocks' do
        should 'tag this test' do
          skip
          assert Tagz.tags.include?(self.class.name + '::' + name)
        end

        should 'also tag this test' do
          skip
          assert Tagz.tags.include?(self.class.name + '::' + name)
        end
      end

      tag :nested_context_tag
      context 'tags on nested context blocks' do
        context 'a nested context block' do
          should 'tag this test' do
            skip
            assert Tagz.tags.include?(self.class.name + '::' + name)
          end

          should 'also tag this test' do
            skip
            assert Tagz.tags.include?(self.class.name + '::' + name)
          end
        end
      end
    end
  end
end
