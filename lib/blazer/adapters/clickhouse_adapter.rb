module Blazer
  module Adapters
    class ClickhouseAdapter < BaseAdapter
      def run_statement(statement, _comment)
        columns = []
        rows = []
        error = nil

        begin
          response = connection.post(query: { query: statement, default_format: "CSVWithNames" })
          rows = response.body
          columns = rows.shift
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        connection.tables
      end

      def schema
        statement = <<-SQL
          SELECT table, name, type
          FROM system.columns
          WHERE database = '#{connection.config.database}'
          ORDER BY table, position
        SQL

        response = connection.post(query: { query: statement, default_format: "CSV" })
        response.body
                .group_by { |row| row[0] }
                .transform_values { |columns| columns.map { |c| { name: c[1], data_type: c[2] } } }
                .map { |table, columns| { schema: "public", table: table, columns: columns } }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      def explain(statement)
        connection.explain(statement)
      end

      protected

      def connection
        @connection ||= ClickHouse::Connection.new(config)
      end

      def config
        @config ||= begin
          uri = URI.parse(settings["url"])
          options = {
            scheme: uri.scheme,
            host: uri.host,
            port: uri.port,
            username: uri.user,
            password: uri.password,
            database: uri.path.split("/").last
          }.compact

          ClickHouse::Config.new(**options)
        end
      end
    end
  end
end
