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

    def variable_defaults
      settings["variable_defaults"] || {}
    end

    def timeout
      settings["timeout"]
    end

    def cache
      settings["cache"]
    end

    def local_time_suffix
      @local_time_suffix ||= Array(settings["local_time_suffix"])
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
            if timeout
              if postgresql? || redshift?
                connection_model.connection.execute("SET statement_timeout = #{timeout.to_i * 1000}")
              elsif mysql?
                connection_model.connection.execute("SET max_execution_time = #{timeout.to_i * 1000}")
              else
                raise Blazer::TimeoutNotSupported, "Timeout not supported for #{adapter_name} adapter"
              end
            end

            result = connection_model.connection.select_all("#{statement} /*#{comment}*/")
            result.each do |untyped_row|
              row = {}
              untyped_row.each do |k, v|
                row[k] = result.column_types.empty? ? v : result.column_types[k].send(:type_cast, v)
              end
              rows << row
            end
          rescue ActiveRecord::StatementInvalid => e
            error = e.message.sub(/.+ERROR: /, "")
            error = Blazer::TIMEOUT_MESSAGE if Blazer::TIMEOUT_ERRORS.any? { |e| error.include?(e) }
          end
        end

        Blazer.cache.write(cache_key, Marshal.dump([rows, Time.now]), expires_in: cache.to_f * 60) if !error && cache
      end

      [rows, error, cached_at]
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
      rows, error, cached_at = run_statement(connection_model.send(:sanitize_sql_array, ["SELECT table_name, column_name, ordinal_position, data_type FROM information_schema.columns WHERE table_schema IN (?)", schemas]))
      Hash[rows.group_by { |r| r["table_name"] }.map { |t, f| [t, f.sort_by { |f| f["ordinal_position"] }.map { |f| f.slice("column_name", "data_type") }] }.sort_by { |t, _f| t }]
    end

    def postgresql?
      ["PostgreSQL", "PostGIS"].include?(adapter_name)
    end

    def redshift?
      ["Redshift"].include?(adapter_name)
    end

    def mysql?
      ["MySQL", "Mysql2", "Mysql2Spatial"].include?(adapter_name)
    end

    protected

    def adapter_name
      connection_model.connection.adapter_name
    end

    def in_transaction
      if use_transaction?
        connection_model.transaction do
          yield
          raise ActiveRecord::Rollback
        end
      else
        yield
      end
    end
  end
end
