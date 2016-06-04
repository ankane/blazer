module Blazer
  class RunQueryJob < ActiveJob::Base
    queue_as :blazer

    def perform(topic, data)
      ActionCable.server.broadcast topic, data: "it works! #{data.inspect}"
    end
  end
end
