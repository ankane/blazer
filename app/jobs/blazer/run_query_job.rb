module Blazer
  class RunQueryJob < ActiveJob::Base
    queue_as :blazer

    def perform(topic, data, user)
      run_query = Blazer::RunQuery.new(data, user)
      ActionCable.server.broadcast topic, data: run_query.render
    end
  end
end
