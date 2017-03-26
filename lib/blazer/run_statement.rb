module Blazer
  class RunStatement
    def perform(data_source, statement, options = {})
      query = options[:query]
      Blazer.transform_statement.call(data_source, statement) if Blazer.transform_statement

      # audit
      if Blazer.audit
        audit = Blazer::Audit.new(statement: statement)
        audit.query = query
        audit.data_source = data_source.id
        audit.user = options[:user]
        audit.save!
      end

      start_time = Time.now
      result = data_source.run_statement(statement, options)
      duration = Time.now - start_time

      if Blazer.audit
        audit.duration = duration if audit.respond_to?(:duration=)
        audit.error = result.error if audit.respond_to?(:error=)
        audit.timed_out = result.timed_out? if audit.respond_to?(:timed_out=)
        audit.cached = result.cached? if audit.respond_to?(:cached=)
        if !result.cached? && duration >= 10
          audit.cost = data_source.cost(statement) if audit.respond_to?(:cost=)
        end
        audit.save! if audit.changed?
      end

      if query && !result.timed_out? && !query.variables.any?
        query.checks.each do |check|
          check.update_state(result)
        end
      end

      result
    end
  end
end
