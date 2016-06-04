module Blazer
  class QueriesChannel < ApplicationCable::Channel
    def subscribed
      @topic = "blazer:queries:#{@topic}"
      stream_from @topic
    end

    def run(data)
      Blazer::RunQueryJob.perform_later(@topic, data)
    end
  end
end
