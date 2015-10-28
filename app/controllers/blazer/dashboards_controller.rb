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
      @queries = @dashboard.dashboard_queries.order(:position).preload(:query).map(&:query)
      @queries.each do |query|
        process_vars(query.statement)
      end
      @bind_vars ||= []

      @smart_vars = {}
      @sql_errors = []
      data_sources = @queries.map { |q| Blazer.data_sources[q.data_source] }.uniq
      @bind_vars.each do |var|
        data_sources.each do |data_source|
          query = data_source.smart_variables[var]
          if query
            rows, error, cached_at = data_source.run_statement(query)
            ((@smart_vars[var] ||= []).concat(rows.map { |v| v.values.reverse })).uniq!
            @sql_errors << error if error
          end
        end
      end
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
        if params[:query_ids].is_a?(Array)
          query_ids = params[:query_ids].map(&:to_i)
          @queries = Blazer::Query.find(query_ids).sort_by { |q| query_ids.index(q.id) }
        end
        if dashboard.save
          if @queries
            @queries.each_with_index do |query, i|
              dashboard_query = dashboard.dashboard_queries.where(query_id: query.id).first_or_initialize
              dashboard_query.position = i
              dashboard_query.save!
            end
            if dashboard.persisted?
              dashboard.dashboard_queries.where.not(query_id: query_ids).destroy_all
            end
          end
          true
        end
      end
    end
  end
end
