module Blazer
  class DashboardQueriesController < BaseController
    def create
      @dashboard_query = Blazer::DashboardQuery.new(dashboard_query_params)
      @dashboard_query.position = @dashboard_query.blazer_dashboard.blazer_dashboard_queries.maximum(:position).to_i + 1

      if @dashboard_query.save
        redirect_to dashboard_path(@dashboard_query.blazer_dashboard_id)
      else
        raise "boom"
      end
    end

    protected

    def dashboard_query_params
      params.require(:dashboard_query).permit(:blazer_dashboard_id, :blazer_query_id)
    end
  end
end
