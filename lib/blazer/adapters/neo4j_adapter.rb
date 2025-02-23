module Blazer
  module Adapters
    class Neo4jAdapter < BaseAdapter
      def run_statement(statement, comment, bind_params)
        columns = []
        rows = []
        error = nil

        begin
          if bolt?
            result = session.run("#{statement} /*#{comment}*/", bind_params).to_a
            columns = result.any? ? result.first.keys.map(&:to_s) : []
            rows = result.map(&:values)
          else
            result = session.query("#{statement} /*#{comment}*/", bind_params)
            columns = result.columns.map(&:to_s)
            rows = []
            result.each do |row|
              rows << columns.map do |c|
                v = row.send(c)
                v = v.properties if v.respond_to?(:properties)
                v
              end
            end
          end
        rescue => e
          error = e.message
          error = Blazer::VARIABLE_MESSAGE if error.include?("Invalid input '$'")
        end

        [columns, rows, error]
      end

      def tables
        if bolt?
          result = session.run("CALL db.labels()").to_a
          result.map { |r| r.values.first }
        else
          result = session.query("CALL db.labels()")
          result.rows.map(&:first)
        end
      end

      def preview_statement
        "MATCH (n:{table}) RETURN n LIMIT 10"
      end

      # https://neo4j.com/docs/cypher-manual/current/syntax/expressions/#cypher-expressions-string-literals
      def quoting
        :backslash_escape
      end

      def parameter_binding
        proc do |statement, variables|
          variables.each_key do |k|
            statement = statement.gsub("{#{k}}") { "$#{k} " }
          end
          [statement, variables]
        end
      end

      protected

      def session
        @session ||= begin
          if bolt?
            uri = URI.parse(settings["url"])
            auth = Neo4j::Driver::AuthTokens.basic(uri.user, uri.password)
            database = uri.path.delete_prefix("/")
            uri.user = nil
            uri.password = nil
            uri.path = ""
            Neo4j::Driver::GraphDatabase.driver(uri, auth).session(database: database)
          else
            require "neo4j/core/cypher_session/adaptors/http"
            http_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new(settings["url"])
            Neo4j::Core::CypherSession.new(http_adaptor)
          end
        end
      end

      def bolt?
        if !defined?(@bolt)
          @bolt = settings["url"].start_with?("bolt")
        end
        @bolt
      end
    end
  end
end
