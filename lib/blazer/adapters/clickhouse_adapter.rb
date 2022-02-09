module Blazer
  module Adapters
    class ClickhouseAdapter < BaseAdapter
      DATE_TIME_TYPES = ["DateTime", "DateTime(%s)", "DateTime64(%d, %s)"].freeze

      def run_statement(statement, _comment)
        columns = []
        rows = []
        error = nil

        begin
          result = connection.select_all(statement)
          unless result.data.blank?
            date_time_columns = result.meta
                                      .select { |column| column["type"].in?(DATE_TIME_TYPES) }
                                      .map { |column| column["name"] }
            columns = result.data.first.keys
            rows = result.data.map { |row| convert_time_columns(row, date_time_columns).values }
          end
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
          WHERE database = currentDatabase()
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
            database: uri.path.sub(/\A\//, ""),
            ssl_verify: settings.fetch("ssl_verify", false)
          }.compact
          ClickHouse::Config.new(**options)
        end
      end

      def convert_time_columns(row, date_time_columns)
        time_values = row.slice(*date_time_columns).transform_values!(&:to_time)
        row.merge(time_values)
      rescue NoMethodError
        row
      end
    end
  end
end
