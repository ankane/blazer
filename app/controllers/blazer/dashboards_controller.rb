module Blazer
  class DashboardsController < BaseController
    before_action :set_dashboard, only: [:show, :edit, :update, :destroy]

    def index
      @dashboards = Blazer::Dashboard.order(:name)
    end

    def new
      @dashboard = Blazer::Dashboard.new
    end

    def create
      @dashboard = Blazer::Dashboard.new

      if update_dashboard(@dashboard)
        redirect_to dashboard_path(@dashboard)
      else
        render :new
      end
    end

    def show
    end

    def edit
    end

    def update
      if update_dashboard(@dashboard)
        redirect_to dashboard_path(@dashboard)
      else
        render :edit
      end
    end

    def destroy
      @dashboard.destroy
      redirect_to dashboards_path
    end

    protected

    def dashboard_params
      params.require(:dashboard).permit(:name)
    end

    def set_dashboard
      @dashboard = Blazer::Dashboard.find(params[:id])
    end

    def update_dashboard(dashboard)
      dashboard.assign_attributes(dashboard_params)
      Blazer::Dashboard.transaction do
        if params[:blazer_query_ids].is_a?(Array)
          query_ids = params[:blazer_query_ids].map(&:to_i)
          @queries = Blazer::Query.find(query_ids).sort_by { |q| query_ids.index(q.id) }
        end
        if dashboard.save
          if @queries
            @queries.each_with_index do |query, i|
              dashboard_query = dashboard.blazer_dashboard_queries.where(blazer_query_id: query.id).first_or_initialize
              dashboard_query.position = i
              dashboard_query.save!
            end
            if dashboard.persisted?
              dashboard.blazer_dashboard_queries.where.not(blazer_query_id: query_ids).destroy_all
            end
          end
          true
        end
      end
    end
  end
end
