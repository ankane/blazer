module Blazer
  class PromptsController < BaseController
    def run
      @query = Query.find_by(id: params[:query_id]) if params[:query_id]

      # use query data source when present
      data_source = @query.data_source if @query && @query.data_source
      data_source ||= params[:data_source]
      @data_source = Blazer.data_sources[data_source]

      @prompt = params[:prompt]

      generated_sql = RunPromptJob.perform_now(data_source, @prompt)
      render plain: generated_sql
    end
  end
end
