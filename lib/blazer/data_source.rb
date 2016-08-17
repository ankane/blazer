require "digest/md5"

module Blazer
  class DataSource
    extend Forwardable

    attr_reader :id, :settings, :adapter, :adapter_instance

    def_delegators :adapter_instance, :schema, :tables, :preview_statement, :reconnect, :cost, :explain

    def initialize(id, settings)
      @id = id
      @settings = settings

      unless settings["url"] || Rails.env.development?
        raise Blazer::Error, "Empty url"
      end

      @adapter_instance =
        case adapter
        when "elasticsearch"
          Blazer::Adapters::ElasticsearchAdapter.new(self)
        when "mongodb"
          Blazer::Adapters::MongodbAdapter.new(self)
        when "postgresql"
          Blazer::Adapters::PostgresqlAdapter.new(self)
        when "presto"
          Blazer::Adapters::PrestoAdapter.new(self)
        when "sql"
          Blazer::Adapters::SqlAdapter.new(self)
        else
          raise Blazer::Error, "Unknown adapter"
        end
    end

    def adapter
      settings["adapter"] || detect_adapter
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
      @cache ||= begin
        if settings["cache"].is_a?(Hash)
          settings["cache"]
        elsif settings["cache"]
          {
            "mode" => "all",
            "expires_in" => settings["cache"]
          }
        else
          {
            "mode" => "off"
          }
        end
      end
    end

    def cache_mode
      cache["mode"]
    end

    def cache_expires_in
      (cache["expires_in"] || 60).to_f
    end

    def cache_slow_threshold
      (cache["slow_threshold"] || 15).to_f
    end

    def local_time_suffix
      @local_time_suffix ||= Array(settings["local_time_suffix"])
    end

    def read_cache(cache_key)
      value = Blazer.cache.read(cache_key)
      if value
        Blazer::Result.new(self, *Marshal.load(value), nil)
      end
    end

    def run_results(run_id)
      read_cache(run_cache_key(run_id))
    end

    def delete_results(run_id)
      Blazer.cache.delete(run_cache_key(run_id))
    end

    def run_statement(statement, options = {})
      run_id = options[:run_id]
      result = nil
      if cache_mode != "off" && !options[:refresh_cache]
        result = read_cache(statement_cache_key(statement))
      end

      unless result
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
        if options[:check]
          comment << ",check_id:#{options[:check].id},check_emails:#{options[:check].emails}"
        end
        result = run_statement_helper(statement, comment, options)
      end

      result
    end

    def clear_cache(statement)
      Blazer.cache.delete(statement_cache_key(statement))
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

    protected

    def run_statement_helper(statement, comment, options)
      start_time = Time.now
      run_id = options[:run_id]
      stop_id = options[:stop_id]
      columns, rows, error = @adapter_instance.run_statement(statement, comment, stop_id)
      duration = Time.now - start_time

      cache_data = nil
      cache = !error && (cache_mode == "all" || (cache_mode == "slow" && duration >= cache_slow_threshold))
      if cache || run_id
        cache_data = Marshal.dump([columns, rows, error, cache ? Time.now : nil]) rescue nil
      end

      if cache && cache_data
        Blazer.cache.write(statement_cache_key(statement), cache_data, expires_in: cache_expires_in.to_f * 60)
      end

      if run_id
        unless cache_data
          error = "Error storing the results of this query :("
          cache_data = Marshal.dump([[], [], error, nil])
        end
        Blazer.cache.write(run_cache_key(run_id), cache_data, expires_in: 30.seconds)
      end

      Blazer::Result.new(self, columns, rows, error, nil, cache && !cache_data.nil?)
    end

    def detect_adapter
      schema = settings["url"].to_s.split("://").first
      case schema
      when "postgres", "postgresql"
        "postgresql"
      when "mongodb", "presto"
        schema
      else
        "sql"
      end
    end
  end
end
