module Blazer
  module Adapters
    class OpensearchAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          response = client.transport.perform_request("POST", "_plugins/_sql", {}, {query: "#{statement} /*#{comment}*/"}).body
          columns = response["schema"].map { |v| v["name"] }
          date_indexes = response["schema"].each_index.select { |i| response["schema"][i]["type"] == "timestamp" }
          if columns.any?
            rows = response["datarows"]
            utc = ActiveSupport::TimeZone["Etc/UTC"]
            date_indexes.each do |i|
              rows.each do |row|
                row[i] &&= utc.parse(row[i])
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
        "SELECT * FROM `{table}` LIMIT 10"
      end

      protected

      def client
        @client ||= OpenSearch::Client.new(url: settings["url"])
      end
    end
  end
end
