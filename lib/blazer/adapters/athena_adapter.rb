module Blazer
  module Adapters
    class AthenaAdapter < BaseAdapter
      def run_statement(statement, comment)
        require "digest/md5"

        columns = []
        rows = []
        error = nil

        begin
          resp =
            client.start_query_execution(
              query_string: statement,
              # use token so we fetch cached results after query is run
              client_request_token: Digest::MD5.hexdigest([statement,data_source.id].join("/")),
              query_execution_context: {
                database: database,
              },
              result_configuration: {
                output_location: settings["output_location"]
              }
            )
          query_execution_id = resp.query_execution_id

          timeout = data_source.timeout || 300
          stop_at = Time.now + timeout
          resp = nil

          begin
            resp = client.get_query_results(
              query_execution_id: query_execution_id
            )
          rescue Aws::Athena::Errors::InvalidRequestException => e
            unless e.message.start_with?("Query has not yet finished.")
              raise e
            end
            if Time.now < stop_at
              sleep(3)
              retry
            end
          end

          if resp && resp.result_set
            column_info = resp.result_set.result_set_metadata.column_info
            columns = column_info.map(&:name)
            column_types = column_info.map(&:type)

            untyped_rows = []

            # paginated
            resp.each do |page|
              untyped_rows.concat page.result_set.rows.map { |r| r.data.map(&:var_char_value) }
            end

            utc = ActiveSupport::TimeZone['Etc/UTC']

            rows = untyped_rows[1..-1] || []
            rows = untyped_rows[0..-1] unless column_info.present?
            column_types.each_with_index do |ct, i|
              # TODO more column_types
              case ct
              when "timestamp"
                rows.each do |row|
                  row[i] = utc.parse(row[i])
                end
              when "date"
                rows.each do |row|
                  row[i] = Date.parse(row[i])
                end
              when "bigint"
                rows.each do |row|
                  row[i] = row[i].to_i
                end
              when "double"
                rows.each do |row|
                  row[i] = row[i].to_f
                end
              end
            end
          elsif resp
            error = fetch_error(query_execution_id)
          else
            error = Blazer::TIMEOUT_MESSAGE
          end
        rescue Aws::Athena::Errors::InvalidRequestException => e
          error = e.message
          if error == "Query did not finish successfully. Final query state: FAILED"
            error = fetch_error(query_execution_id)
          end
        end

        [columns, rows, error]
      end

      def tables
        glue.get_tables(database_name: database).table_list.map(&:name).sort
      end

      def schema
        glue.get_tables(database_name: database).table_list.map { |t| {table: t.name, columns: t.storage_descriptor.columns.map { |c| {name: c.name, data_type: c.type} }} }
      end

      def preview_statement
        "SELECT * FROM {table} LIMIT 10"
      end

      private

      def database
        @database ||= settings["database"] || "default"
      end

      def fetch_error(query_execution_id)
        client.get_query_execution(
          query_execution_id: query_execution_id
        ).query_execution.status.state_change_reason
      end

      def client
        @client ||= Aws::Athena::Client.new
      end

      def glue
        @glue ||= Aws::Glue::Client.new
      end
    end
  end
end
