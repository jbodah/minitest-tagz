module Minitest
  module Tagz
    module MinitestPatch
      def run(*args)
        # Check for no match and don't filter runnable methods if there would be no match
        if Tagz.run_all_if_no_match?
          run_map = Minitest::Runnable.runnables.reduce({}) {|memo, r| memo[r] = r.runnable_methods; memo}
          should_skip_filter = run_map.all? do |ctxt, methods|
            methods.all? do |m|
              serialized = Tagz.serialize(ctxt, m)
              tags = Tagz.tag_map[serialized]
              tags.nil? ||
                tags.empty? ||
                ((tags & Tagz.positive_tags).empty? &&
                 (tags & Tagz.negative_tags).empty?)
            end
          end
          if should_skip_filter
            puts "Couldn't find any runnables with the given tag, running all runnables" if Tagz.log_if_no_match?
            return super
          end
        end

        Minitest::Test.singleton_class.class_eval { prepend(MinitestPatch::RunnableMethodsPatch) }
        super
      end

      # Patch which is used ot filter Minitest's `runnable_methods`
      module RunnableMethodsPatch
        def runnable_methods
          all_runnables = super

          if Tagz.positive_tags.any?
            all_runnables.select! do |r|
              serialized = Tagz.serialize(self, r)
              tags_on_runnable = Tagz.tag_map[serialized]
              next false unless tags_on_runnable
              (Tagz.positive_tags - tags_on_runnable).empty?
            end
          end

          if Tagz.negative_tags.any?
            all_runnables.reject! do |r|
              serialized = Tagz.serialize(self, r)
              tags_on_runnable = Tagz.tag_map[serialized]
              next false unless tags_on_runnable
              (Tagz.negative_tags & tags_on_runnable).any?
            end
          end

          all_runnables
        end
      end
    end
  end
end
