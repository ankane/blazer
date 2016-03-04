require "sucker_punch"

module Blazer
  class RunStatementJob
    include SuckerPunch::Job

    def perform(data_source, statement, comment, run_id)
      ActiveRecord::Base.connection_pool.with_connection do
        data_source.send(:run_statement_helper, statement, comment, run_id)
      end
    end
  end
end
