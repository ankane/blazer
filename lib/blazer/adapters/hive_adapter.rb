module Blazer
  module Adapters
    class HiveAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          result = client.execute("#{statement} /*#{comment}*/")
          columns = result.any? ? result.first.keys : []
          rows = result.map(&:values)
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        client.execute("SHOW TABLES").map { |r| r["tab_name"] }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      protected

      def client
        @client ||= begin
          uri = URI.parse(settings["url"])
          Hexspace::Client.new(
            host: uri.host,
            port: uri.port,
            username: uri.user,
            password: uri.password,
            database: uri.path.sub(/\A\//, ""),
            mode: uri.scheme.to_sym
          )
        end
      end
    end
  end
end
