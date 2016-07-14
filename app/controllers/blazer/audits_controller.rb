module Blazer
  class AuditsController < BaseController
    before_action :set_query

    def index
      @audits = @query.audits.order("created_at DESC").limit(100)
    end

    private

    def set_query
      @query = Blazer::Query.find(params[:query_id].to_s.split("-").first)
    end

  end
end
