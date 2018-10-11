module Blazer
  module Adapters
    class ElasticsearchAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          response = client.xpack.sql.query(body: {query: "#{statement} /*#{comment}*/"})
          columns = response["columns"].map { |v| v["name"] }
          # Elasticsearch does not differentiate between dates and times
          date_indexes = response["columns"].each_index.select { |i| response["columns"][i]["type"] == "date" }
          if columns.any?
            rows = response["rows"]
            date_indexes.each do |i|
              rows.each do |row|
                row[i] = Time.parse(row[i])
              end
            end
          end
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        indices = client.cat.indices(format: "json").map { |v| v["index"] }
        aliases = client.cat.aliases(format: "json").map { |v| v["alias"] }
        (indices + aliases).uniq.sort
      end

      def preview_statement
        "SELECT * FROM \"{table}\" LIMIT 10"
      end

      protected

      def client
        @client ||= Elasticsearch::Client.new(url: settings["url"])
      end
    end
  end
end
