module Blazer
  module Adapters
    class ClickhouseAdapter < BaseAdapter
      def run_statement(statement, comment, bind_params)
        columns = []
        rows = []
        error = nil

        begin
          res = execute("#{statement} /*#{comment}*/", bind_params)

          if res.is_a?(Net::HTTPSuccess)
            data = JSON.parse(res.body)
            columns = data["meta"].map { |v| v["name"] }
            rows = data["data"]
            data["meta"].each_with_index do |c, i|
              type = c["type"]
              type = type[9..-2] if type.start_with?("Nullable(")
              if type.start_with?("DateTime")
                utc = ActiveSupport::TimeZone["Etc/UTC"]
                rows.each do |row|
                  row[i] &&= utc.parse(row[i])
                end
              elsif ["Date", "Date32"].include?(type)
                rows.each do |row|
                  row[i] &&= Date.parse(row[i])
                end
              end
            end
          else
            error = res.body
            error = Blazer::TIMEOUT_MESSAGE if error.include?("TIMEOUT_EXCEEDED")
          end
        rescue Errno::ECONNREFUSED => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        result = data_source.run_statement("SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE table_schema = currentDatabase() ORDER BY table_name")
        result.rows.map(&:first)
      end

      def schema
        result = data_source.run_statement("SELECT table_schema, table_name, column_name, data_type, ordinal_position FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = currentDatabase() ORDER BY 1, 2")
        result.rows.group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      # https://clickhouse.com/docs/sql-reference/syntax#string
      def quoting
        :backslash_escape
      end

      def parameter_binding
        proc do |statement, variables|
          variables.each do |k, v|
            if v.nil?
              statement = statement.gsub("{#{k}}") { "NULL" }
            else
              type =
                case v
                when Integer
                  # TODO improve
                  "Int64"
                when Float
                  "Float64"
                when ActiveSupport::TimeWithZone
                  "DateTime64(9, 'UTC')"
                else
                  "String"
                end
              statement = statement.gsub("{#{k}}") { "{#{k}: #{type}}" }
            end
          end
          [statement, variables]
        end
      end

      def cancel(run_id)
        execute("KILL QUERY WHERE query LIKE {query: String} AND query NOT LIKE '%system.processes%' SYNC", {"query" => "%,run_id:#{run_id}%"})
      end

      private

      def database
        @database ||= settings["database"] || "default"
      end

      def execute(statement, bind_params)
        require "net/http"

        query_params = {
          "database" => database,
          "default_format" => "JSONCompact",
          "output_format_json_quote_64bit_integers" => 0, # for ClickHouse < 25.8
          "readonly" => 1
        }
        query_params["max_execution_time"] = data_source.timeout if data_source.timeout

        post_data = {
          "query" => statement
        }
        bind_params.each do |k, v|
          v = v.utc.strftime("%Y-%m-%d %H:%M:%S.%N") if v.is_a?(ActiveSupport::TimeWithZone)
          # https://github.com/ClickHouse/ClickHouse/issues/69656
          v = v.gsub("\\") { "\\\\" } if v.is_a?(String)
          post_data["param_#{k}"] = v.to_s unless v.nil?
        end

        uri = URI(settings["url"])
        raise "Not supported" if uri.query
        uri.query = URI.encode_www_form(query_params)

        req = Net::HTTP::Post.new(uri)
        req.basic_auth(uri.user, uri.password) if uri.user || uri.password
        req.set_form(post_data, "multipart/form-data")

        options = {
          use_ssl: uri.scheme == "https",
          open_timeout: 3,
          read_timeout: data_source.timeout ? data_source.timeout + 3 : 30
        }

        Net::HTTP.start(uri.hostname, uri.port, options) do |http|
          http.request(req)
        end
      end
    end
  end
end
