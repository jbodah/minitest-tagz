# Adds the `tag` method to Minitest::Test. When we encounter a `tag` then we
# want to create a state machine that will be used to patch/unpatch Minitest
module Minitest
  module Tagz
    module MinitestTestPatch
      def tag(*tags)
        state_machine = Tagger.new([Minitest::Tagz::Patcher], self, tags)
        state_machine.tags_declared!
        state_machine
      end
    end
  end
end
