require "sucker_punch"

module Blazer
  class RunStatementJob
    include SuckerPunch::Job
    workers 4

    def perform(result, data_source, statement, options)
      ActiveRecord::Base.connection_pool.with_connection do
        data_source.connection_model.connection_pool.with_connection do
          result << data_source.run_main_statement(statement, options)
        end
      end
    end
  end
end
