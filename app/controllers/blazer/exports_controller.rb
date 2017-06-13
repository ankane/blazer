module Blazer
  class ExportsController < BaseController
    before_action :set_query

    def show
      return head :forbidden unless @query.public
      redirect_to queries_path(query_id: @query.id, format: "csv"), params: {statement: @query.statement}
    end

    private

    def set_query
      @query = Blazer::Query.find_by(pid: params[:pid])
    end
  end
end
