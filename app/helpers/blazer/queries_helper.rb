module Blazer
  module QueriesHelper

    def gpt?(query)
      defined?(OpenAI) && (params[:gpt].present? || query.gpt_prompt.present?)
    end
  end
end
