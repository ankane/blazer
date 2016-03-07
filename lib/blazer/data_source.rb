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

    def read_cache(cache_key)
      value = Blazer.cache.read(cache_key)
      Marshal.load(value) if value
    end

    def run_results(run_id)
      read_cache(run_cache_key(run_id))
    end

    def run_statement(statement, options = {})
      rows = nil
      error = nil
      cached_at = nil
      run_id = options[:run_id]
      cache_key = statement_cache_key(statement)
      if cache && !options[:refresh_cache]
        rows, error, cached_at = read_cache(cache_key)
      end

      unless rows
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

        if run_id
          Blazer::RunStatementJob.perform_async(self, statement, comment, run_id)
        else
          rows, error = run_statement_helper(statement, comment)
        end
      end

      [rows, error, cached_at]
    end

    def clear_cache(statement)
      Blazer.cache.delete(cache_key(statement))
    end

    def cache_key(key)
      (["blazer", "v4"] + key).join("/")
    end

    def statement_cache_key(statement)
      cache_key(["statement", id, Digest::MD5.hexdigest(statement)])
    end

    def run_cache_key(run_id)
      cache_key(["run", run_id])
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

    def run_statement_helper(statement, comment, run_id = nil)
      rows = []
      error = nil

      in_transaction do
        begin
          connection_model.connection.execute("SET statement_timeout = #{timeout.to_i * 1000}") if timeout && (postgresql? || redshift?)
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
          error = Blazer::TIMEOUT_MESSAGE if error.include?("canceling statement due to statement timeout") || error.include?("cancelled on user's request")
        end
      end

      if run_id || (cache && !error)
        cache_key = run_id ? run_cache_key(run_id) : statement_cache_key(statement)
        cached_at = run_id ? nil : Time.now
        Blazer.cache.write(cache_key, Marshal.dump([rows, error, cached_at]), expires_in: (cache || 2).to_f * 60)
      end

      [rows, error]
    end
  end
end
