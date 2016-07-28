module Blazer
  module Adapters
    class ElasticsearchAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          response = client.search(body: JSON.parse(statement))
          columns = ["response"]
          rows = [[response]]
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        client.indices.get_aliases.map { |k, v| [k, v["aliases"].keys] }.flatten.uniq
      end

      protected

      def client
        @client ||= Elasticsearch::Client.new(url: settings["url"])
      end
    end
  end
end
