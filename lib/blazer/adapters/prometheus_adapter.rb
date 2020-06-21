module Blazer
  module Adapters
    class PrometheusAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          result = client.query(query: statement)
          p result
        rescue => e
          raise e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        client.run_command("metadata", {}).keys
      end

      def preview_statement
        "{table}"
      end

      protected

      def client
        @client ||= begin
          require "prometheus/api_client"
          Prometheus::ApiClient.client(url: settings["url"])
        end
      end
    end
  end
end
