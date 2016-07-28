module Blazer
  module Adapters
    class BaseAdapter
      attr_reader :data_source

      def initialize(data_source)
        @data_source = data_source
      end

      def run_statement(statement, comment)
      end

      def tables
      end

      def reconnect
      end

      def cost(statement)
      end

      def explain(statement)
      end
    end
  end
end
