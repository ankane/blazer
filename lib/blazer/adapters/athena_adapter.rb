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
              client_request_token: Digest::MD5.hexdigest(statement),
              query_execution_context: {
                database: settings["database"],
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
            if e.message != "Query has not yet finished. Current state: RUNNING"
              raise e
            end
            if Time.now < stop_at
              sleep(3)
              retry
            end
          end

          if resp
            column_info = resp.result_set.result_set_metadata.column_info
            columns = column_info.map(&:name)
            column_types = column_info.map(&:type)

            untyped_rows = []
            resp.each do |page|
              untyped_rows.concat page.result_set.rows.map { |r| r.data.map(&:var_char_value) }
            end

            rows = untyped_rows[1..-1] # TODO use column_types
          else
            error = Blazer::TIMEOUT_MESSAGE
          end
        rescue Aws::Athena::Errors::InvalidRequestException => e
          error = e.message
        end

        [columns, rows, error]
      end

      private

      def client
        @client ||= Aws::Athena::Client.new
      end
    end
  end
end
