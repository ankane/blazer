module Blazer
  module Adapters
    class Snowflake2Adapter < BaseAdapter
      def run_statement(statement, comment, bind_params)
        require "json"
        require "net/http"

        columns = []
        rows = []
        error = nil

        api_prefix = "https://#{settings.fetch("account_id")}.snowflakecomputing.com/api/v2/statements/"
        authorization = "Bearer #{settings.fetch("access_token")}"

        submit_uri = URI(api_prefix)
        # for testing
        # submit_uri.query = URI.encode_www_form({"async" => true})

        post_data = {
          statement: "#{statement} /*#{comment}*/"
        }
        # use empty? since any? doesn't work for [nil]
        unless bind_params.empty?
          post_data[:bindings] =
            bind_params.map.with_index.to_h do |v, i|
              type =
                case v
                when Integer
                  "FIXED"
                when Float
                  "REAL"
                when ActiveSupport::TimeWithZone
                  "TIMESTAMP_NTZ"
                else
                  "TEXT"
                end
              v = v.to_i * 1000000000 + v.nsec if v.is_a?(ActiveSupport::TimeWithZone)
              [i + 1, {type: type, value: v&.to_s}]
            end
        end
        post_data[:timeout] = data_source.timeout if data_source.timeout
        post_data[:database] = settings["database"] if settings["database"]
        post_data[:schema] = settings["schema"] if settings["schema"]
        post_data[:warehouse] = settings["warehouse"] if settings["warehouse"]
        post_data[:role] = settings["role"] if settings["role"]

        req = Net::HTTP::Post.new(submit_uri)
        req["Authorization"] = authorization
        req.body = post_data.to_json

        options = {
          use_ssl: true,
          open_timeout: 3,
          read_timeout: data_source.timeout ? data_source.timeout + 3 : 60
        }

        begin
          res = Net::HTTP.start(submit_uri.hostname, submit_uri.port, options) do |http|
            http.request(req)
          end

          while res.is_a?(Net::HTTPAccepted)
            sleep(1)

            data = JSON.parse(res.body)
            statement_uri = URI("#{api_prefix}#{CGI.escape(data["statementHandle"])}")
            req = Net::HTTP::Get.new(statement_uri)
            req["Authorization"] = authorization

            res = Net::HTTP.start(statement_uri.hostname, statement_uri.port, options) do |http|
              http.request(req)
            end
          end

          if res.is_a?(Net::HTTPSuccess)
            data = JSON.parse(res.body)
            metadata = data["resultSetMetaData"]
            columns = metadata["rowType"].map { |v| v["name"].downcase }
            column_types = metadata["rowType"].map { |v| v["type"] }
            rows = data["data"]

            if metadata["partitionInfo"]
              1.upto(metadata["partitionInfo"].size - 1) do |i|
                statement_uri.query = URI.encode_www_form({"partition" => i})
                req = Net::HTTP::Get.new(statement_uri)
                req["Authorization"] = authorization

                res = Net::HTTP.start(statement_uri.hostname, statement_uri.port, options) do |http|
                  http.request(req)
                end

                if res.is_a?(Net::HTTPSuccess)
                  data = JSON.parse(res.body)
                  rows += data["data"]
                else
                  data = JSON.parse(res.body)
                  error = data["message"]
                  break
                end
              end
            end

            if error
              columns.clear
              rows.clear
            else
              column_types.each_with_index do |c, i|
                # TODO handle more types
                case c
                when "fixed"
                  rows.each do |row|
                    row[i] &&= row[i].to_i
                  end
                when "real"
                  rows.each do |row|
                    row[i] &&= row[i].to_f
                  end
                when "timestamp_ntz"
                  utc = ActiveSupport::TimeZone["Etc/UTC"]
                  rows.each do |row|
                    row[i] &&= utc.strptime(row[i], "%s.%N")
                  end
                end
              end
            end
          else
            data = JSON.parse(res.body)
            error = data["message"]
            error = Blazer::TIMEOUT_MESSAGE if error.include?("Statement reached its statement or warehouse timeout")
          end
        rescue Errno::ECONNREFUSED => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        sql = "SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema != 'INFORMATION_SCHEMA'"
        result = data_source.run_statement(sql)
        result.rows.sort_by { |r| [r[0] == default_schema ? "" : r[0], r[1]] }.map do |row|
          table =
            if row[0] == default_schema
              row[1]
            else
              "#{row[0]}.#{row[1]}"
            end

          # TODO quote if needed
          table.downcase
        end
      end

      def schema
        sql = "SELECT table_schema, table_name, column_name, data_type, ordinal_position FROM information_schema.columns WHERE table_schema != 'INFORMATION_SCHEMA'"
        result = data_source.run_statement(sql)
        result.rows.group_by { |r| [r[0], r[1]] }.sort_by { |k, _| [k[0] == default_schema ? "" : k[0], k[1]] }.map { |k, vs| {schema: k[0].downcase, table: k[1].downcase, columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2].downcase, data_type: v[3].downcase} }} }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      # https://docs.snowflake.com/en/sql-reference/data-types-text#escape-sequences-in-single-quoted-string-constants
      def quoting
        :backslash_escape
      end

      # https://docs.snowflake.com/en/developer-guide/sql-api/submitting-requests#label-sql-api-bind-variables
      def parameter_binding
        :positional
      end

      # https://docs.snowflake.com/en/developer-guide/sql-api/cancelling-requests
      def cancel(run_id)
        # TODO
      end

      private

      def default_schema
        @default_schema ||=
          if settings["schema"]
            settings["schema"]
          else
            data_source.run_statement("SELECT CURRENT_SCHEMA()").rows[0][0]
          end
      end
    end
  end
end
