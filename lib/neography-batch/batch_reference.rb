require_relative 'neography_context.rb'

module Neography
  module Composable
    class BatchReference
      def initialize(command)
        @command = command
      end

      protected
      def after_submit_action
        @after_submit_action
      end

      def command
        @command
      end

      public
      def after_submit(&after_commit_action)
        @after_submit_action = after_commit_action
      end

      def notify_after_submit(result)
        unless @after_submit_action.nil?
          NeographyContext.new(&@after_submit_action).eval(result)
        end
      end

      def ==(other)
        return false if other.nil?
        @after_submit_action.equal?(other.after_submit_action) &&
            @command.equal?(other.command)
      end
    end
  end
end