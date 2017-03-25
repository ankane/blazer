module Blazer
  module Adapters
    class BigQueryAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil
        begin
          results = bigquery.query(statement, timeout: timeout_ms)
          columns = results.first.keys.map(&:to_s)
          rows = results.map(&:values)
        rescue StandardError => e
          error = e.message
        end
        [columns, rows, error]
      end

      def tables
        table_refs.map{|t| "#{t.project_id}.#{t.dataset_id}.#{t.table_id}" }
      end

      def schema
        table_refs.map{|table_ref| 
          {
            schema: table_ref.dataset_id,
            table: table_ref.table_id,
            columns: table_columns(table_ref)
          }
        }
      end

      def preview_statement
        "SELECT * FROM `{table}` LIMIT 10"
      end

      private

      def bigquery
        @bigquery ||= connect!
      end

      def connect!
        require "google/cloud/bigquery"
        params = { project: settings["project"], keyfile: settings["keyfile"] }
        @bigquery = Google::Cloud::Bigquery.new(params)
        ::Google::Apis.logger.level = Logger::INFO
        @bigquery
      end

      def table_refs
        bigquery
          .datasets
          .map(&:tables)
          .flat_map { |table_list| table_list.map(&:table_ref) }
      end

      def table_columns(table_ref)
        schema = 
          bigquery
          .service
          .get_table(table_ref.dataset_id, table_ref.table_id)
          .schema
        return [] if schema.nil?
        schema
          .fields
          .map { |field| { name: field.name, data_type: field.type} }
      end

      def timeout_ms
        30 * 1000 # 30 seconds
      end
    end
  end
end
