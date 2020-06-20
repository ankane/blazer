module Blazer
  module Adapters
    class InfluxdbAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          result = client.query(statement, denormalize: false).first
          # TODO parse times
          rows = result["values"]
          columns = result["columns"]
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        client.list_series
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      protected

      def client
        @client ||= InfluxDB::Client.new(url: settings["url"])
      end
    end
  end
end
