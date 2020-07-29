module Blazer
  module Adapters
    class InfluxdbAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          result = client.query(statement, denormalize: false).first
          columns = result["columns"]
          rows = result["values"]

          # parse time columns
          # current approach isn't ideal, but result doesn't include types
          # another approach would be to check the format
          time_index = columns.index("time")
          if time_index
            rows.each do |row|
              row[time_index] = Time.parse(row[time_index]) if row[time_index]
            end
          end
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
