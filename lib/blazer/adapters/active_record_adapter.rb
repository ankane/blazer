module Blazer
  module Adapters
    class ActiveRecordAdapter
      attr_reader :data_source, :connection_model

      def initialize(data_source)
        @data_source = data_source

        @connection_model =
          Class.new(Blazer::Connection) do
            def self.name
              "Blazer::Connection::#{object_id}"
            end
            establish_connection(data_source.settings["url"]) if data_source.settings["url"]
          end
      end

      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          in_transaction do
            set_timeout(data_source.timeout) if data_source.timeout

            result = connection_model.connection.select_all("#{statement} /*#{comment}*/")
            columns = result.columns
            cast_method = Rails::VERSION::MAJOR < 5 ? :type_cast : :cast_value
            result.rows.each do |untyped_row|
              rows << (result.column_types.empty? ? untyped_row : columns.each_with_index.map { |c, i| untyped_row[i] ? result.column_types[c].send(cast_method, untyped_row[i]) : nil })
            end
          end
        rescue ActiveRecord::StatementInvalid => e
          error = e.message.sub(/.+ERROR: /, "")
          error = Blazer::TIMEOUT_MESSAGE if Blazer::TIMEOUT_ERRORS.any? { |e| error.include?(e) }
        end

        [columns, rows, error]
      end

      def tables
        result = data_source.run_statement(connection_model.send(:sanitize_sql_array, ["SELECT table_name FROM information_schema.tables WHERE table_schema IN (?) ORDER BY table_name", schemas]))
        result.rows.map(&:first)
      end

      def reconnect
        connection_model.establish_connection(settings["url"])
      end

      def cost(statement)
        result = explain(statement)
        match = /cost=\d+\.\d+..(\d+\.\d+) /.match(result)
        match[1] if match
      end

      def explain(statement)
        if postgresql? || redshift?
          connection_model.connection.select_all("EXPLAIN #{statement}").rows.first.first
        end
      rescue
        nil
      end

      private

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
        connection_model.connection.adapter_name
      end

      def schemas
        default_schema = (postgresql? || redshift?) ? "public" : connection_model.connection_config[:database]
        settings["schemas"] || [connection_model.connection_config[:schema] || default_schema]
      end

      def set_timeout(timeout)
        if postgresql? || redshift?
          connection_model.connection.execute("SET statement_timeout = #{timeout.to_i * 1000}")
        elsif mysql?
          connection_model.connection.execute("SET max_execution_time = #{timeout.to_i * 1000}")
        else
          raise Blazer::TimeoutNotSupported, "Timeout not supported for #{adapter_name} adapter"
        end
      end

      def use_transaction?
        settings.key?("use_transaction") ? settings["use_transaction"] : true
      end

      def in_transaction
        if use_transaction?
          connection_model.transaction do
            yield
            raise ActiveRecord::Rollback
          end
        else
          yield
        end
      end

      def settings
        @data_source.settings
      end
    end
  end
end
