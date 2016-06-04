module Blazer
  class QueriesChannel < ApplicationCable::Channel
    def subscribed
      @topic = params[:topic]
      stream_from "blazer:queries:#{@topic}"
    end

    def run(data)
      p data
      ActionCable.server.broadcast "blazer:queries:#{@topic}", data: "it works!"
    end
  end
end
