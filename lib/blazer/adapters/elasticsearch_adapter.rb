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
          source_keys = hits.flat_map { |r| r["_source"].keys }.uniq
          hit_keys = ["_score", "_id", "_index", "_type"]
          columns = source_keys + hit_keys
          rows =
            hits.map do |r|
              source = r["_source"]
              source_keys.map { |k| source[k] } + hit_keys.map { |k| r[k] }
            end
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
