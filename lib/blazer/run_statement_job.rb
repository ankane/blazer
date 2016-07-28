require "sucker_punch"

module Blazer
  class RunStatementJob
    include SuckerPunch::Job
    workers 4

    def perform(result, data_source, statement, options)
      ActiveRecord::Base.connection_pool.with_connection do
        data_source.connection_model.connection_pool.with_connection do
          result << RunStatement.new.perform(data_source, statement, options)
        end
      end
    end
  end
end
