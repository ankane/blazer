module Blazer
  module Adapters
    class BaseAdapter
      attr_reader :data_source

      def initialize(data_source)
        @data_source = data_source
      end

      def run_statement(statement, comment)
        # the one required method
      end

      def tables
        [] # optional, but nice to have
      end

      def reconnect
        # optional
      end

      def cost(statement)
        # optional
      end

      def explain(statement)
        # optional
      end
    end
  end
end
