module Blazer
  module Adapters
    class InfluxdbAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          result = client.query(statement)
          values = result.first["values"]
          values.each do |r|
            r["time"] = Time.parse(r["time"]) if r["time"]
          end
          rows = values.map { |r| r.values }
          columns = values.any? ? values.first.keys : []
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
