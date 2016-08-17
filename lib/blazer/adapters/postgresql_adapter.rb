module Blazer
  module Adapters
    class PostgresqlAdapter
      attr_reader :data_source

      def initialize(data_source)
        @data_source = data_source

        uri = URI.parse(data_source.settings["url"])
        connect_args = [uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password]

        @pool =
          ConnectionPool.new(size: 5, timeout: 5) do
            conn = PG::Connection.open(*connect_args)
            conn.type_map_for_results = PG::BasicTypeMapForResults.new(conn)
            conn
          end
      end

      def run_statement(statement, comment, stop_id)
        columns = []
        rows = []
        error = nil

        @pool.with do |conn|
          conn.send_query("#{statement} /*#{comment}*/")

          loop do
            success = conn.block(0.1)
            if success
              result = conn.get_last_result
              columns = result.fields
              rows = result.values
              break
            else
              if Blazer.cache.read(["blazer", "v4", "stop", stop_id].join("/"))
                conn.cancel
                conn.get_last_result rescue nil
                error = "Canceled"
                break
              end
            end
          end
        end

        [columns, rows, error]
      end

      def tables
        [] # optional, but nice to have
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      def reconnect
        # optional
      end

      def cost(statement)
        # optional
      end

      def explain(statement)
        # optional
      end

      protected

      def settings
        @data_source.settings
      end
    end
  end
end
