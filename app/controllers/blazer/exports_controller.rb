module Blazer
  class ExportsController < BaseController
    before_action :set_query

    include ::Blazer::QueryRunner

    def show
      return head :forbidden unless @query.public

      run_command(@query.statement)
    end

    private

    def set_query
      @query = Blazer::Query.find_by(pid: params[:pid])
    end
  end
end
