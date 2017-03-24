module Blazer
  module Adapters
    class DrillAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        drill = ::Drill.new(url: settings["url"])
        begin
          response = drill.query(statement)
          rows = response.map { |r| r.values }
          columns = rows.any? ? response.first.keys : []
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end
    end
  end
end
