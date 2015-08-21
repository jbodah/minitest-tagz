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

    class MinitestAdapterSpec < Minitest::Spec
      after do
        Tagz.choose_tags
      end

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

      #describe 'describe blocks' do
        #describe 'with a tag specified' do
          #it 'runs top level tests in the describe block' do
            #assert MinitestSpecExampleWithDescribe.runnable_methods.include?()
          #end

          #it 'runs tests of nested describe blocks' do
            #fail
          #end

          #it 'does not run top level tests without that tag' do
            #fail
          #end

          #it 'does not run tests of other describe blocks without that tag' do
            #fail
          #end
        #end
      #end
    end
  end
end
