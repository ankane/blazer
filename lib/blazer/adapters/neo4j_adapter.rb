module Blazer
  module Adapters
    class Neo4jAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          result = session.query("#{statement} /*#{comment}*/")
          columns = result.columns.map(&:to_s)
          rows = []
          result.each do |row|
            rows << columns.map do |c|
              v = row.send(c)
              v = v.properties if v.respond_to?(:properties)
              v
            end
          end
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        result = session.query("CALL db.labels()")
        result.rows.map(&:first)
      end

      def preview_statement
        "MATCH (n:{table}) RETURN n LIMIT 10"
      end

      protected

      def session
        @session ||= begin
          require "neo4j/core/cypher_session/adaptors/http"
          http_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new(settings["url"])
          Neo4j::Core::CypherSession.new(http_adaptor)
        end
      end
    end
  end
end
