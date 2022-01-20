module Blazer
  module Adapters
    class ClickhouseAdapter < BaseAdapter
      SUPPORTED_DRIVERS_MAPPING = {
        "click_house" => ClickHouseDriver,
        "clickhouse-activerecord" => ClickhouseActiverecordDriver
      }.freeze

      delegate :tables, to: :driver

      # Wrapper for ClickHouse Ruby driver (https://github.com/shlima/click_house)
      class ClickHouseDriver
        delegate :tables, to: :connection

        def initialize(config)
          @config = ClickHouse::Config.new(**config)
        end

        def connection
          @connection ||= ClickHouse::Connection.new(@config)
        end

        def execute(statement, format)
          connection.post(query: { query: statement, default_format: format }).body
        end
      end

      # Wrapper for Clickhouse::Activerecord driver (https://github.com/PNixx/clickhouse-activerecord)
      class ClickhouseActiverecordDriver
        delegate :tables, to: :connection

        def initialize(config)
          @config = config
        end

        def connection
          @connection ||= ActiveRecord::Base.clickhouse_connection(@config)
        end

        def execute(statement, format)
          body = connection.do_execute(statement, format: format)
          format.in?(%w[CSV CSVWithNames]) ? CSV.parse(body) : body
        end
      end

      def run_statement(statement, _comment)
        columns = []
        rows = []
        error = nil

        begin
          rows = driver.execute(statement, "CSVWithNames")
          columns = rows.shift
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def schema
        statement = <<-SQL
          SELECT table, name, type
          FROM system.columns
          WHERE database = '#{config[:database]}'
          ORDER BY table, position
        SQL

        rows = driver.execute(statement, "CSV")
        rows.group_by { |row| row[0] }
            .transform_values { |columns| columns.map { |c| { name: c[1], data_type: c[2] } } }
            .map { |table, columns| { schema: "public", table: table, columns: columns } }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      def explain(statement)
        driver.execute("EXPLAIN #{statement.gsub(/\A(\s*EXPLAIN)/io, '')}", "TSV")
      end

      protected

      def driver
        @driver ||= begin
          driver = SUPPORTED_DRIVERS_MAPPING.keys.find { |driver| installed?(driver) }
          raise Blazer::Error, "ClickHouse driver not installed!" unless driver

          SUPPORTED_DRIVERS_MAPPING[driver].new(config)
        end
      end

      def config
        @config ||= begin
          uri = URI.parse(settings["url"])
          {
            scheme: uri.scheme,
            host: uri.host,
            port: uri.port,
            username: uri.user,
            password: uri.password,
            database: uri.path.split("/").last
          }.compact
        end
      end

      def installed?(driver_name)
        Gem::Specification.find_by_name(driver_name)
        true
      rescue Gem::LoadError
        false
      end
    end
  end
end
