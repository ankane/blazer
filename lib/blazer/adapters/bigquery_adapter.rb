module Blazer
  module Adapters
    class BigQueryAdapter < BaseAdapter
      def run_statement(statement, comment)
        columns = []
        rows = []
        error = nil

        begin
          options = {}
          options[:timeout] = data_source.timeout.to_i * 1000 if data_source.timeout
          results = bigquery.query(statement, options) # ms

          if results.present?
            columns = results.first.keys.map(&:to_s) if results.size > 0
            rows = results.map(&:values)
          else
            error = Blazer::TIMEOUT_MESSAGE
          end
        rescue => e
          error = e.message
        end

        [columns, rows, error]
      end

      def tables
        table_refs.map { |t| "#{t.project_id}.#{t.dataset_id}.#{t.table_id}" }
      end

      def schema
        table_refs.map do |table_ref|
          {
            schema: table_ref.dataset_id,
            table: table_ref.table_id,
            columns: table_columns(table_ref)
          }
        end
      end

      def preview_statement
        "SELECT * FROM `{table}` LIMIT 10"
      end

      private

      def bigquery
        @bigquery ||= begin
          require "google/cloud/bigquery"
          Google::Cloud::Bigquery.new(
            project: settings["project"],
            keyfile: settings["keyfile"]
          )
        end
      end

      def table_refs
        bigquery.datasets.map(&:tables).flat_map { |table_list| table_list.map(&:table_ref) }
      end

      def table_columns(table_ref)
        schema = bigquery.service.get_table(table_ref.dataset_id, table_ref.table_id).schema
        return [] if schema.nil?
        schema.fields.map { |field| {name: field.name, data_type: field.type} }
      end
    end
  end
end
