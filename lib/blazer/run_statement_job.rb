module Blazer
  class RunStatementJob < ActiveJob::Base
    self.queue_adapter = :async

    def perform(result, data_source_id, statement, options)
      data_source = Blazer.data_sources[data_source_id]
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
