module Blazer
  module Adapters
    class ElasticsearchAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          response = client.search(body: JSON.parse(statement))
          hits = response["hits"]["hits"]
          columns = hits.first.try(:keys) || []
          rows = hits.map { |r| r.values }
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        client.indices.get_aliases.map { |k, v| [k, v["aliases"].keys] }.flatten.uniq.sort
      end

      protected

      def client
        @client ||= Elasticsearch::Client.new(url: settings["url"])
      end
    end
  end
end
