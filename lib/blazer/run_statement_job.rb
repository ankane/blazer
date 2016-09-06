require "sucker_punch"

module Blazer
  class RunStatementJob
    include SuckerPunch::Job
    workers 4

    def perform(result, data_source, statement, options)
      begin
        ActiveRecord::Base.connection_pool.with_connection do
          result << Blazer::RunStatement.new.perform(data_source, statement, options)
        end
      rescue Exception => e
        result.clear
        result << Blazer::Result.new(data_source, [], [], "Unknown error", nil, false)
        Blazer.cache.write(data_source.run_cache_key(options[:run_id]), Marshal.dump([[], [], "Unknown error", nil]), expires_in: 30.seconds)
        raise e
      end
    end
  end
end
