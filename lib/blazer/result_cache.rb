module Blazer
  class ResultCache
    def initialize(data_source)
      @data_source = data_source
    end

    def write_run(run_id, result)
      write(run_cache_key(run_id), result, expires_in: 30.seconds)
    end

    def read_run(run_id)
      read(run_cache_key(run_id))
    end

    def delete_run(run_id)
      delete(run_cache_key(run_id))
    end

    def write_statement(statement, result, expires_in:)
      write(statement_cache_key(statement), result, expires_in: expires_in) if caching?
    end

    def read_statement(statement)
      read(statement_cache_key(statement)) if caching?
    end

    def delete_statement(statement)
      delete(statement_cache_key(statement)) if caching?
    end

    private

    def write(key, result, expires_in:)
      raise ArgumentError, "expected Blazer::Result" unless result.is_a?(Blazer::Result)
      value = [result.columns, result.rows, result.error, result.cached_at, result.just_cached]
      cache.write(key, value, expires_in: expires_in)
    end

    def read(key)
      value = cache.read(key)
      if value
        columns, rows, error, cached_at, just_cached = value
        Blazer::Result.new(@data_source, columns, rows, error, cached_at, just_cached)
      end
    end

    def delete(key)
      cache.delete(key)
    end

    def caching?
      @data_source.cache_mode != "off"
    end

    def cache_key(key)
      (["blazer", "v5", @data_source.id] + key).join("/")
    end

    def statement_cache_key(statement)
      cache_key(["statement", Digest::SHA256.hexdigest(statement.bind_statement.to_s.gsub("\r\n", "\n") + statement.bind_values.to_json)])
    end

    def run_cache_key(run_id)
      cache_key(["run", run_id])
    end

    def cache
      Blazer.cache
    end
  end
end
