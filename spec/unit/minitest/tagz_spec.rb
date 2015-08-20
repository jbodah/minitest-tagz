require 'spec_helper'

module Minitest
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

  class TagzSpec < Minitest::Spec
    after do
      Minitest::Tagz.choose_tags
    end

    describe 'with multiple tags specified' do
      before do
        Minitest::Tagz.choose_tags(:login, :fast)
      end

      it 'runs tests with all of the tags' do
        assert Minitest::MinitestSpecExample.runnable_methods.include?('test_0002_tests things with the :login and :fast tags')
      end

      it 'does not run tests with only some of the tags' do
        refute Minitest::MinitestSpecExample.runnable_methods.include?('test_0001_tests things with the :login tag')
      end

      it 'does not run tests with none of the tags' do
        refute Minitest::MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags')
      end
    end

    describe 'with a single tag specified' do
      before do
        Minitest::Tagz.choose_tags(:login)
      end

      it 'runs tests with that tag' do
        assert Minitest::MinitestSpecExample.runnable_methods.include?('test_0001_tests things with the :login tag')
        assert Minitest::MinitestSpecExample.runnable_methods.include?('test_0002_tests things with the :login and :fast tags')
      end

      it 'does not run tests without that tag' do
        refute Minitest::MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags')
      end
    end

    describe 'without a tag specified' do
      it 'runs all tests' do
        assert Minitest::MinitestSpecExample.runnable_methods.include?('test_0001_tests things with the :login tag')
        assert Minitest::MinitestSpecExample.runnable_methods.include?('test_0002_tests things with the :login and :fast tags')
        assert Minitest::MinitestSpecExample.runnable_methods.include?('test_0003_tests things with no tags')
      end
    end
  end
end
