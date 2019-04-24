module Blazer
  module Adapters
    class SodaAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        # remove comments manually
        # statement = statement.gsub(/--.+/, "")
        # only supports single line /* */ comments
        # regex not perfect, but should be good enough
        # statement = statement.gsub(/\/\*.+\*\//, "")

        # remove trailing semicolon
        # statement = statement.sub(/;\s*\z/, "")

        begin
          response = client.get(settings["url"], "$query" => statement).body
          rows = response.map { |r| r.to_hash.select { |k, v| !k.start_with?(":@") }.values }
          columns = rows.any? ? response.first.to_hash.select { |k, v| !k.start_with?(":@") }.keys : []
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def preview_statement
        "SELECT * LIMIT 10"
      end

      def tables
        ["table"]
      end

      protected

      def client
        @client ||= begin
          require "soda"
          SODA::Client.new(app_token: settings["app_token"])
        end
      end
    end
  end
end
