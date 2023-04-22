module Blazer
  class RunStatementJob < ActiveJob::Base
    self.queue_adapter = :async

    def perform(data_source_id, statement, options)
      statement = Blazer::Statement.new(statement, data_source_id)
      statement.values = options.delete(:values)
      data_source = statement.data_source
      begin
        ActiveRecord::Base.connection_pool.with_connection do
          Blazer::RunStatement.new.perform(statement, options)
        end
      rescue Exception => e
        result = Blazer::Result.new(data_source, [], [], "Unknown error", nil, false)
        data_source.result_cache.write_run(options[:run_id], result)
        raise e
      end
    end
  end
end
