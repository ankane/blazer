module Blazer
  module Adapters
    class SqlAdapter < BaseAdapter
      attr_reader :connection_model

      def initialize(data_source)
        super

        @connection_model =
          Class.new(Blazer::Connection) do
            def self.name
              "Blazer::Connection::Adapter#{object_id}"
            end
            establish_connection(data_source.settings["url"]) if data_source.settings["url"]
          end
      end

      def run_statement(statement, comment, bind_params = [])
        columns = []
        rows = []
        error = nil

        begin
          result = nil
          in_transaction do
            set_timeout(data_source.timeout) if data_source.timeout
            binds = bind_params.map { |v| ActiveRecord::Relation::QueryAttribute.new(nil, v, ActiveRecord::Type::Value.new) }
            result = connection_model.connection.select_all("#{statement} /*#{comment}*/", nil, binds)
          end

          columns = result.columns
          result.rows.each do |untyped_row|
            rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] && result.column_types[c] ? result.column_types[c].send(:cast_value, untyped_row[i]) : untyped_row[i] })
          end

          # fix for non-ASCII column names and charts
          if adapter_name == "Trilogy"
            columns.map! { |k| k.dup.force_encoding(Encoding::UTF_8) }
          end
        rescue => e
          error = e.message.sub(/.+ERROR: /, "")
          error = Blazer::TIMEOUT_MESSAGE if Blazer::TIMEOUT_ERRORS.any? { |e| error.include?(e) }
          error = Blazer::VARIABLE_MESSAGE if error.include?("syntax error at or near \"$") || error.include?("Incorrect syntax near '@") || error.include?("your MySQL server version for the right syntax to use near '?")
          if error.include?("could not determine data type of parameter")
            error += " - try adding casting to variables and make sure none are inside a string literal"
          end
          reconnect if error.include?("PG::ConnectionBad")
        end

        [columns, rows, error]
      end

      def tables
        sql = add_schemas("SELECT table_schema, table_name FROM information_schema.tables")
        result = data_source.run_statement(sql, refresh_cache: true)
        if postgresql? || redshift? || snowflake?
          result.rows.sort_by { |r| [r[0] == default_schema ? "" : r[0], r[1]] }.map do |row|
            table =
              if row[0] == default_schema
                row[1]
              else
                "#{row[0]}.#{row[1]}"
              end

            table = table.downcase if snowflake?

            {
              table: table,
              value: connection_model.connection.quote_table_name(table)
            }
          end
        else
          result.rows.map(&:second).sort
        end
      end

      def schema
        sql = add_schemas("SELECT table_schema, table_name, column_name, data_type, ordinal_position FROM information_schema.columns")
        result = data_source.run_statement(sql)
        result.rows.group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }.sort_by { |t| [t[:schema] == default_schema ? "" : t[:schema], t[:table]] }
      end

      def preview_statement
        if sqlserver?
          "SELECT TOP (10) * FROM {table}"
        else
          "SELECT * FROM {table} LIMIT 10"
        end
      end

      def reconnect
        connection_model.establish_connection(settings["url"])
      end

      def cost(statement)
        result = explain(statement)
        if sqlserver?
          result["TotalSubtreeCost"]
        else
          match = /cost=\d+\.\d+..(\d+\.\d+) /.match(result)
          match[1] if match
        end
      end

      def explain(statement)
        if postgresql? || redshift?
          select_all("EXPLAIN #{statement}").rows.first.first
        elsif sqlserver?
          begin
            execute("SET SHOWPLAN_ALL ON")
            result = select_all(statement).each.first
          ensure
            execute("SET SHOWPLAN_ALL OFF")
          end
          result
        end
      rescue
        nil
      end

      def cancel(run_id)
        if postgresql?
          select_all("SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE pid <> pg_backend_pid() AND query LIKE ?", ["%,run_id:#{run_id}%"])
        elsif redshift?
          first_row = select_all("SELECT pid FROM stv_recents WHERE status = 'Running' AND query LIKE ?", ["%,run_id:#{run_id}%"]).first
          if first_row
            select_all("CANCEL #{first_row["pid"].to_i}")
          end
        end
      end

      def cachable?(statement)
        !%w[CREATE ALTER UPDATE INSERT DELETE].include?(statement.split.first.to_s.upcase)
      end

      def supports_cohort_analysis?
        postgresql? || mysql?
      end

      # TODO treat date columns as already in time zone
      def cohort_analysis_statement(statement, period:, days:)
        raise "Cohort analysis not supported" unless supports_cohort_analysis?

        cohort_column = statement =~ /\bcohort_time\b/ ? "cohort_time" : "conversion_time"
        tzname = Blazer.time_zone.tzinfo.name

        if mysql?
          time_sql = "CONVERT_TZ(#{cohort_column}, '+00:00', ?)"
          case period
          when "day"
            date_sql = "CAST(DATE_FORMAT(#{time_sql}, '%Y-%m-%d') AS DATE)"
            date_params = [tzname]
          when "week"
            date_sql = "CAST(DATE_FORMAT(#{time_sql} - INTERVAL ((5 + DAYOFWEEK(#{time_sql})) % 7) DAY, '%Y-%m-%d') AS DATE)"
            date_params = [tzname, tzname]
          when "quarter"
            date_sql = "CAST(DATE_FORMAT(CONCAT(YEAR(#{time_sql}), '-', QUARTER(#{time_sql}) * 3 - 2, '-01'), '%Y-%m-%d') AS DATE)"
            date_params = [tzname]
          else
            date_sql = "CAST(DATE_FORMAT(#{time_sql}, '%Y-%m-01') AS DATE)"
            date_params = [tzname]
          end
        else
          date_sql = "DATE_TRUNC(?, #{cohort_column}::timestamptz AT TIME ZONE ?)::date"
          date_params = [period, tzname]
        end

        statement = <<~SQL
          WITH query AS (
            {placeholder}
          ),
          min_user_date AS (
            SELECT user_id, MIN(#{date_sql}) AS cohort_date 
            FROM query
            WHERE user_id IS NOT NULL 
              AND #{cohort_column} IS NOT NULL
            GROUP BY 1
          ),
          user_detail AS (
            SELECT #{date_sql} AS conversion_date,
              user_id
            FROM query
            ORDER BY 2, 1
          )
          SELECT mud.cohort_date AS period,
            ud.conversion_date AS period_bucket,
            COUNT(DISTINCT ud.user_id) AS period_bucket_size
          FROM min_user_date mud
            JOIN user_detail ud ON mud.user_id = ud.user_id
          GROUP BY 1, 2
          ORDER BY 1, 2
        SQL
        params = [statement] + date_params + date_params
        connection_model.send(:sanitize_sql_array, params)
      end

      def quoting
        ->(value) { connection_model.connection.quote(value) }
      end

      # Redshift adapter silently ignores binds
      def parameter_binding
        if postgresql?
          :numeric
        elsif sqlite? && prepared_statements?
          # Active Record silently ignores binds with SQLite when prepared statements are disabled
          :numeric
        elsif mysql? && prepared_statements?
          # Active Record silently ignores binds with MySQL when prepared statements are disabled
          :positional
        elsif sqlserver?
          proc do |statement, variables|
            variables.each_with_index do |(k, _), i|
              statement = statement.gsub("{#{k}}", "@#{i} ")
            end
            [statement, variables.values]
          end
        end
      end

      protected

      def select_all(statement, params = [])
        statement = connection_model.send(:sanitize_sql_array, [statement] + params) if params.any?
        connection_model.connection.select_all(statement)
      end

      # seperate from select_all to prevent mysql error
      def execute(statement)
        connection_model.connection.execute(statement)
      end

      def postgresql?
        ["PostgreSQL", "PostGIS"].include?(adapter_name)
      end

      def redshift?
        ["Redshift"].include?(adapter_name)
      end

      def mysql?
        ["MySQL", "Mysql2", "Mysql2Spatial", "Trilogy"].include?(adapter_name)
      end

      def sqlite?
        ["SQLite"].include?(adapter_name)
      end

      def sqlserver?
        ["SQLServer", "tinytds", "mssql"].include?(adapter_name)
      end

      def snowflake?
        data_source.adapter == "snowflake"
      end

      def adapter_name
        # prevent bad data source from taking down queries/new
        connection_model.connection.adapter_name rescue nil
      end

      def default_schema
        @default_schema ||= begin
          if postgresql? || redshift?
            "public"
          elsif sqlserver?
            "dbo"
          elsif connection_model.respond_to?(:connection_db_config)
            connection_model.connection_db_config.database
          else
            connection_model.connection_config[:database]
          end
        end
      end

      def add_schemas(query)
        if settings["schemas"]
          where = "table_schema IN (?)"
          schemas = settings["schemas"]
        elsif mysql?
          where = "table_schema IN (?)"
          schemas = [default_schema]
        else
          where = "table_schema NOT IN (?)"
          schemas = ["information_schema"]
          schemas.map!(&:upcase) if snowflake?
          schemas << "pg_catalog" if postgresql? || redshift?
        end
        connection_model.send(:sanitize_sql_array, ["#{query} WHERE #{where}", schemas])
      end

      def set_timeout(timeout)
        if postgresql? || redshift?
          execute("SET #{use_transaction? ? "LOCAL " : ""}statement_timeout = #{timeout.to_i * 1000}")
        elsif mysql?
          # use send as this method is private in Rails 4.2
          mariadb = connection_model.connection.send(:mariadb?) rescue false
          if mariadb
            execute("SET max_statement_time = #{timeout.to_i * 1000}")
          else
            execute("SET max_execution_time = #{timeout.to_i * 1000}")
          end
        else
          raise Blazer::TimeoutNotSupported, "Timeout not supported for #{adapter_name} adapter"
        end
      end

      def use_transaction?
        settings.key?("use_transaction") ? settings["use_transaction"] : true
      end

      def in_transaction
        connection_model.connection_pool.with_connection do
          if use_transaction?
            connection_model.transaction do
              yield
              raise ActiveRecord::Rollback
            end
          else
            yield
          end
        end
      end

      def prepared_statements?
        connection_model.connection.prepared_statements
      end
    end
  end
end
