module Blazer
  class Annotations
    attr_reader :annotations

    def initialize(annotations)
      @annotations = annotations.values
    end

    def call(result)
      return [] unless result.chart_type.in?(["line", "line2"])
      min, max = result.rows.map(&:first).minmax
      annotations.map { |annotation| fetch_annotation(annotation, result, min, max) }.flatten
    end

    private

    def fetch_annotation(annotation, result, min_date, max_date)
      query = build_query(annotation, max_date, min_date)
      results = result.data_source.run_statement(query)
      return [] unless results.error.nil?

      if results.columns.size == 3 # boxes
        results.rows.map do |row|
          {
            min_date: row[0],
            max_date: row[1],
            label: row[2],
          }
        end
      elsif results.columns.size == 2 # lines
        results.rows.map do |row|
          {
            min_date: row[0],
            label: row[1],
          }
        end
      else
        []
      end
    end

    def build_query(annotation, max_date, min_date)
      annotation = annotation.sub("{min_date}", "(:min_date)").sub("{max_date}", "(:max_date)")
      ActiveRecord::Base.send(:sanitize_sql_array, [annotation, {min_date: min_date, max_date: max_date}])
    end
  end
end
