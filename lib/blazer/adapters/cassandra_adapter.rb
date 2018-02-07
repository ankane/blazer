module Blazer
  module Adapters
    class CassandraAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          response = session.execute("#{statement} /*#{comment}*/")
          rows = response.map { |r| r.values }
          columns = rows.any? ? response.first.keys : []
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        session.execute("SELECT table_name FROM system_schema.tables WHERE keyspace_name = '#{keyspace}'").map { |r| r["table_name"] }
      end

      def schema
        result = session.execute("SELECT keyspace_name, table_name, column_name, type, position FROM system_schema.columns WHERE keyspace_name = '#{keyspace}'")
        result.map(&:values).group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      private

      def cluster
        @cluster ||= begin
          require "cassandra"
          options = {hosts: [uri.host]}
          options[:port] = uri.port if uri.port
          options[:username] = uri.user if uri.user
          options[:password] = uri.password if uri.password
          ::Cassandra.cluster(options)
        end
      end

      def session
        @session ||= cluster.connect(keyspace)
      end

      def uri
        @uri ||= URI.parse(data_source.settings["url"])
      end

      def keyspace
        @keyspace ||= uri.path[1..-1]
      end
    end
  end
end
