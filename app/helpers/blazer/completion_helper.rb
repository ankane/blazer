module Blazer
  module CompletionHelper
    BLAZER_COMPLETION_COLUMN_SCORE = 1001
    BLAZER_COMPLETION_COLUMN_META = 'column_name'
    BLAZER_COMPLETION_TABLE_SCORE = 1000
    BLAZER_COMPLETION_TABLE_META = 'table_name'

    def extract_tables_and_columns(schema)
      schema.map do |schema_entry|
        [schema_entry[:table], schema_entry[:columns]]
      end
    end

    def blazer_table_name_completion_source
      extract_tables_and_columns(Blazer.data_sources['main'].schema).collect do |entry|
        {
          value: entry.first,
          columns: entry.last.map do |column|
            {
              value: column[:name],
              score: BLAZER_COMPLETION_COLUMN_SCORE,
              meta: BLAZER_COMPLETION_COLUMN_META
            }
          end,
          score: BLAZER_COMPLETION_TABLE_SCORE,
          meta: BLAZER_COMPLETION_TABLE_META
        }
      end.to_json
    end
  end
end
