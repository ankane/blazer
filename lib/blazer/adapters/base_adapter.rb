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

      def schema
        [] # optional, but nice to have
      end

      def preview_statement
        "" # also optional, but nice to have
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

      def cancel(run_id)
        # optional
      end

      def cachable?(statement)
        true # optional
      end

      def supports_cohort_analysis?
        false # optional
      end

      def cohort_analysis_statement(statement, period:, days:)
        # optional
      end

      protected

      def settings
        @data_source.settings
      end
    end
  end
end
