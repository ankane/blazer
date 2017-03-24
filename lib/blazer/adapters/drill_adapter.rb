module Blazer
  module Adapters
    class DrillAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          # remove trailing semicolon
          response = drill.query(statement.sub(/;\s*\z/, ""))
          columns = response["columns"]
          rows = response["rows"].map { |r| columns.map { |c| r[c] } }
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      private

      def drill
        @drill ||= ::Drill.new(url: settings["url"])
      end
    end
  end
end
