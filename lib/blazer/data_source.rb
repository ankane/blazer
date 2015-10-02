module Blazer
  class DataSource
    attr_reader :id, :settings, :connection_model

    def initialize(id, settings)
      @id = id
      @settings = settings
      @connection_model =
        Class.new(Blazer::Connection) do
          def self.name
            "Blazer::Connection::#{object_id}"
          end
          establish_connection(settings["url"])
        end
    end

    def name
      settings["name"] || @id
    end

    def linked_columns
      settings["linked_columns"] || {}
    end

    def smart_columns
      settings["smart_columns"] || {}
    end

    def smart_variables
      settings["smart_variables"] || {}
    end

    def timeout
      settings["timeout"]
    end

    def run_statement(statement)
      rows = []
      error = nil
      begin
        connection_model.transaction do
          connection_model.connection.execute("SET statement_timeout = #{timeout.to_i * 1000}") if timeout && postgresql?
          result = connection_model.connection.select_all(statement)
          result.each do |untyped_row|
            row = {}
            untyped_row.each do |k, v|
              row[k] = result.column_types.empty? ? v : result.column_types[k].send(:type_cast, v)
            end
            rows << row
          end
          raise ActiveRecord::Rollback
        end
      rescue ActiveRecord::StatementInvalid => e
        error = e.message.sub(/.+ERROR: /, "")
      end
      [rows, error]
    end

    def tables
      default_schema = postgresql? ? "public" : connection_model.connection_config[:database]
      schema = connection_model.connection_config[:schema] || default_schema
      rows, error = run_statement(connection_model.send(:sanitize_sql_array, ["SELECT table_name, column_name, ordinal_position, data_type FROM information_schema.columns WHERE table_schema = ?", schema]))
      Hash[rows.group_by { |r| r["table_name"] }.map { |t, f| [t, f.sort_by { |f| f["ordinal_position"] }.map { |f| f.slice("column_name", "data_type") }] }.sort_by { |t, _f| t }]
    end

    def postgresql?
      ["PostgreSQL", "Redshift"].include?(connection_model.connection.adapter_name)
    end
  end
end
