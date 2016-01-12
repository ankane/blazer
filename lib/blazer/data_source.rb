require "digest/md5"

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
          establish_connection(settings["url"]) if settings["url"]
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

    def cache
      settings["cache"]
    end

    def use_transaction?
      settings.key?("use_transaction") ? settings["use_transaction"] : true
    end

    def run_statement(statement, options = {})
      rows = nil
      error = nil
      cached_at = nil
      cache_key = self.cache_key(statement) if cache
      if cache && !options[:refresh_cache]
        value = Blazer.cache.read(cache_key)
        rows, cached_at = Marshal.load(value) if value
      end

      unless rows
        rows = []
        columns = []

        comment = "blazer"
        if options[:user].respond_to?(:id)
          comment << ",user_id:#{options[:user].id}"
        end
        if options[:user].respond_to?(Blazer.user_name)
          # only include letters, numbers, and spaces to prevent injection
          comment << ",user_name:#{options[:user].send(Blazer.user_name).to_s.gsub(/[^a-zA-Z0-9 ]/, "")}"
        end
        if options[:query].respond_to?(:id)
          comment << ",query_id:#{options[:query].id}"
        end

        in_transaction do
          begin
            connection_model.connection.execute("SET statement_timeout = #{timeout.to_i * 1000}") if timeout && (postgresql? || redshift?)
            result = connection_model.connection.select_all("#{statement} /*#{comment}*/")
            column_hash = {}
            dupe_columns = []
            result.columns.each_with_index do |column, col_number|
              orig_name = column
              uniq_col_idx = 1
              while column_hash[column].present?
                uniq_col_idx += 1
                column = "#{orig_name}_#{uniq_col_idx}"
                dupe_columns << orig_name
              end
              column_hash[column] = {name: column, orig_name: orig_name, col_number: col_number}
            end

            # Append a "_1" to the first of every duplicate set
            dupe_columns.uniq.each do |column|
              column_hash["#{column}_1"] = column_hash.delete(column).merge({name: "#{column}_1"})
            end

            columns = column_hash.values.sort_by { |column| column[:col_number] }

            result.rows.each do |untyped_row|
              row = {}
              columns.each do |column|
                value = untyped_row[column[:col_number]]
                row[column[:name]] = result.column_types.empty? ? value : result.column_types[column[:orig_name]].send(:type_cast, value)
              end
              rows << row
            end
          rescue ActiveRecord::StatementInvalid => e
            error = e.message.sub(/.+ERROR: /, "")
          end
        end

        Blazer.cache.write(cache_key, Marshal.dump([rows, Time.now]), expires_in: cache.to_f * 60) if !error && cache
      end

      [columns, rows, error, cached_at]
    end

    def clear_cache(statement)
      Blazer.cache.delete(cache_key(statement))
    end

    def cache_key(statement)
      ["blazer", "v2", id, Digest::MD5.hexdigest(statement)].join("/")
    end

    def schemas
      default_schema = (postgresql? || redshift?) ? "public" : connection_model.connection_config[:database]
      settings["schemas"] || [connection_model.connection_config[:schema] || default_schema]
    end

    def tables
      columns, rows, error, cached_at = run_statement(connection_model.send(:sanitize_sql_array, ["SELECT table_name, column_name, ordinal_position, data_type FROM information_schema.columns WHERE table_schema IN (?)", schemas]))
      Hash[rows.group_by { |r| r["table_name"] }.map { |t, f| [t, f.sort_by { |f| f["ordinal_position"] }.map { |f| f.slice("column_name", "data_type") }] }.sort_by { |t, _f| t }]
    end

    def postgresql?
      connection_model.connection.adapter_name == "PostgreSQL"
    end

    def redshift?
      connection_model.connection.adapter_name == "Redshift"
    end

    protected

    def in_transaction
      if use_transaction?
        connection_model.transaction do
          begin
            yield
          ensure
            raise ActiveRecord::Rollback
          end
        end
      else
        yield
      end
    end
  end
end
