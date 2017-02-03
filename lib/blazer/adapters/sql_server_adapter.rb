module Blazer
  module Adapters
    # A MS SQL Server Adapter for Blazer
    # Overrides some methods with SQL Server specific implementations of SqlAdapter
    class SqlServerAdapter < SqlAdapter

      def preview_statement
        "SELECT TOP (10) * FROM {table}"
      end

      # Difficult to implement, see #explain
      def cost(statement)
        raise NotImplementedError
      end

      # The equivalent of Explain is difficult to acquire in this environment.
      # ```sql
      # SET SHOWPLAN_ALL ON
      # GO
      # SELECT * FROM TABLE
      # GO
      # SET SHOWPLAN_ALL OFF
      # GO
      # ```
      #
      # SET SHOWPLAN must be the only statement in the batch,
      # so you can't send a string of queries.
      def explain(statement)
        raise NotImplementedError
      end

      # Kills a query.
      # Custom query to find a pid for a specific query text
      # Getting a pid works, but actually KILLING the query is UNTESTED,
      #   not sure how to test beyond running the query in SSMS and saying "Okay."
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
          WHERE D.text like '%,run_id:#{run_id}%'
        SQL
        ).first
        if first_row
          select_all("kill #{first_row["pid"].to_i}")
        end
      end

      protected

      def schemas
        default_schema = "dbo"
        settings["schemas"] || [connection_model.connection_config[:schema] || default_schema]
      end

      # In SQL Server you cannot set timeout for a single transaction,
      #  it's scoped by client(tinytds) or server wide. Let's not do that.
      def set_timeout(timeout)
        raise Blazer::TimeoutNotSupported, "Timeout not supported for #{adapter_name} adapter"
      end

    end
  end
end
