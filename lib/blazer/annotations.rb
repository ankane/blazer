module Blazer
  class Annotations
    attr_reader :annotations

    def initialize(annotations)
      @annotations = annotations.map { |name, annotation| { query: annotation, name: name } }
    end

    def call(result)
      return [] unless result.chart_type.in?(["line", "line2"])
      min, max = result.rows.map(&:first).minmax
      annotations.map { |annotation| fetch_annotation(annotation, result, min, max) }.flatten
    end

    private

    def fetch_annotation(annotation, result, min_date, max_date)
      query = build_query(annotation, max_date, min_date)
      results = result.data_source.run_statement(query).rows
      if results.first.size == 3 # boxes
        results.map do |row|
          {
            min_date: row[0],
            max_date: row[1],
            label: row[2],
          }
        end
      elsif results.first.size == 2 # lines
        results.map do |row|
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
      query = annotation[:query]
      query = ActiveRecord::Base.send(:sanitize_sql_array, [query.sub("{min_date}", "(?)"), min_date])
      ActiveRecord::Base.send(:sanitize_sql_array, [query.sub("{max_date}", "(?)"), max_date])
    end
  end
end
