module Blazer
  module Adapters
    class SqlServerAdapter < SqlAdapter

      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          in_transaction do
            set_timeout(data_source.timeout) if data_source.timeout

            result = select_all("#{statement} /*#{comment}*/")
            columns = result.columns
            cast_method = Rails::VERSION::MAJOR < 5 ? :type_cast : :cast_value
            result.rows.each do |untyped_row|
              rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] ? result.column_types[c].send(cast_method, untyped_row[i]) : untyped_row[i] })
            end
          end
        rescue => e
          error = e.message.sub(/.+ERROR: /, "")
          error = Blazer::TIMEOUT_MESSAGE if Blazer::TIMEOUT_ERRORS.any? { |e| error.include?(e) }
          reconnect if error.include?("PG::ConnectionBad")
        end

        [columns, rows, error]
      end

      def tables
        result = data_source.run_statement(connection_model.send(:sanitize_sql_array, ["SELECT table_name FROM information_schema.tables WHERE table_schema IN (?) ORDER BY table_name", schemas]), refresh_cache: true)
        result.rows.map(&:first)
      end

      def schema
        result = data_source.run_statement(connection_model.send(:sanitize_sql_array, ["SELECT table_schema, table_name, column_name, data_type, ordinal_position FROM information_schema.columns WHERE table_schema IN (?) ORDER BY 1, 2", schemas]))
        result.rows.group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }
      end

      def preview_statement
        if postgresql?
          "SELECT * FROM \"{table}\" LIMIT 10"
        else
          "SELECT * FROM {table} LIMIT 10"
        end
      end

      def reconnect
        connection_model.establish_connection(settings["url"])
      end

      # Difficult to implement, see #explain
      def cost(statement)
        raise NotImplementedError
      end

      # The equivalent of Explain is difficult to acquire in this environment.
      # SET SHOWPLAN_ALL ON
      # GO
      # SELECT * etc
      # SET SHOWPLAN_ALL OFF
      #
      # SET SHOWPLAN must be the only statement in the batch,
      # so you can't send a string of queries.
      def explain(statement)
        raise NotImplementedError
      end

      # Kills a query.
      # Custom query to obtain the query text along with the spid
      def cancel(run_id)
        first_row = select_all( <<-SQL
          SELECT
            D.text query,
            A.Session_ID pid,
            ISNULL(B.status,A.status) Status
          FROM sys.dm_exec_sessions A
          LEFT JOIN sys.dm_exec_requests B
          ON A.session_id = B.session_id
          LEFT JOIN
            (SELECT A.request_session_id SPID,
              B.blocking_session_id BlkBy
              FROM sys.dm_tran_locks AS A
              INNER JOIN sys.dm_os_waiting_tasks AS B
              ON A.lock_owner_address = B.resource_address) C
          ON A.Session_ID = C.SPID OUTER APPLY sys.dm_exec_sql_text(sql_handle) D
          WHERE ISNULL(B.status,A.status) = 'running'
            AND query like ',run_id:#{run_id}%'
        SQL
        ).first
        if first_row
          select_all("kill #{first_row["pid"].to_id}")
        end
      end

      def cachable?(statement)
        !%w[CREATE ALTER UPDATE INSERT DELETE].include?(statement.split.first.to_s.upcase)
      end

      protected

      def select_all(statement)
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
        ["MySQL", "Mysql2", "Mysql2Spatial"].include?(adapter_name)
      end

      def adapter_name
        # prevent bad data source from taking down queries/new
        connection_model.connection.adapter_name rescue nil
      end

      def schemas
        default_schema = (postgresql? || redshift?) ? "public" : connection_model.connection_config[:database]
        settings["schemas"] || [connection_model.connection_config[:schema] || default_schema]
      end

      def set_timeout(timeout)
        if postgresql? || redshift?
          execute("SET #{use_transaction? ? "LOCAL " : ""}statement_timeout = #{timeout.to_i * 1000}")
        elsif mysql?
          execute("SET max_execution_time = #{timeout.to_i * 1000}")
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
    end
  end
end
