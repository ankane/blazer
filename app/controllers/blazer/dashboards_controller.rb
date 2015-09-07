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
      @dashboard = Blazer::Dashboard.new(dashboard_params)

      if @dashboard.save
        redirect_to dashboard_path(@dashboard)
      else
        render :new
      end
    end

    def show
    end

    protected

    def dashboard_params
      params.require(:dashboard).permit(:name)
    end

    def set_dashboard
      @dashboard = Blazer::Dashboard.find(params[:id])
    end
  end
end
