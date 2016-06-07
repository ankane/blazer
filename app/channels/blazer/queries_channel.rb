module Blazer
  class QueriesChannel < ApplicationCable::Channel
    def subscribed
      @topic = "blazer:queries:#{SecureRandom.uuid}"
      stream_from @topic
    end

    def run(data)
      Blazer::RunQueryJob.perform_later(@topic, data, nil)
    end
  end
end
