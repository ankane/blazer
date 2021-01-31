module Blazer
  module Adapters
    class IgniteAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        uri = URI("#{settings["url"].chomp("/")}/ignite")
        uri.query = URI.encode_www_form(
          "cmd" => "qryfldexe",
          "pageSize" => 1_000_000_000, # TODO paginate
          "cacheName" => "PUBLIC",
          "qry" => "#{statement} /*#{comment}*/"
        )

        req = Net::HTTP::Get.new(uri)

        options = {
          use_ssl: uri.scheme == "https",
          open_timeout: 3,
          read_timeout: 30
        }

        begin
          res = Net::HTTP.start(uri.hostname, uri.port, options) do |http|
            http.request(req)
          end

          if res.is_a?(Net::HTTPSuccess)
            body = JSON.parse(res.body)

            if body["successStatus"] == 0
              columns = body["response"]["fieldsMetadata"].map { |v| v["fieldName"] } if columns.empty?
              rows = body["response"]["items"]

              body["response"]["fieldsMetadata"].each_with_index do |field, i|
                case field["fieldTypeName"]
                when "java.sql.Date"
                  rows.each do |row|
                    row[i] = Date.parse(row[i])
                  end
                when "java.sql.Timestamp"
                  # TODO get server time zone
                  utc = ActiveSupport::TimeZone["Etc/UTC"]
                  rows.each do |row|
                    row[i] = utc.parse(row[i])
                  end
                end
              end
            else
              error = body["error"]
            end
          else
            error = JSON.parse(res.body)["message"] rescue "Bad response: #{res.code}"
          end
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      def tables
        sql = "SELECT table_schema, table_name FROM information_schema.tables WHERE table_schema NOT IN ('INFORMATION_SCHEMA', 'SYS')"
        result = data_source.run_statement(sql)
        result.rows.reject { |row| row[1].start_with?("__") }.map do |row|
          (row[0] == default_schema ? row[1] : "#{row[0]}.#{row[1]}").downcase
        end
      end

      # TODO figure out error
      # Table `__T0` can be accessed only within Ignite query context.
      # def schema
      #   sql = "SELECT table_schema, table_name, column_name, data_type, ordinal_position FROM information_schema.columns WHERE table_schema NOT IN ('INFORMATION_SCHEMA', 'SYS')"
      #   result = data_source.run_statement(sql)
      #   result.rows.group_by { |r| [r[0], r[1]] }.map { |k, vs| {schema: k[0], table: k[1], columns: vs.sort_by { |v| v[2] }.map { |v| {name: v[2], data_type: v[3]} }} }.sort_by { |t| [t[:schema] == default_schema ? "" : t[:schema], t[:table]] }
      # end

      def default_schema
        "PUBLIC"
      end
    end
  end
end
