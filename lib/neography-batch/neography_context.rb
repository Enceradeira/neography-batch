module Neography
  module Composable
    class NeographyContext
      include Neography::Rest::Helpers

      def initialize(&block)
        @block = block
      end

      public
      def eval(result)
        instance_exec(result, &@block)
      end
    end
  end
end