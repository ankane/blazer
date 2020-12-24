module Blazer
  class DashboardsController < BaseController
    before_action :set_dashboard, only: [:show, :edit, :update, :destroy, :refresh]

    def new
      @dashboard = Blazer::Dashboard.new
    end

    def create
      @dashboard = Blazer::Dashboard.new
      # use creator_id instead of creator
      # since we setup association without checking if column exists
      @dashboard.creator = blazer_user if @dashboard.respond_to?(:creator_id=) && blazer_user

      if update_dashboard(@dashboard)
        redirect_to dashboard_path(@dashboard)
      else
        render_errors @dashboard
      end
    end

    def show
      @queries = @dashboard.dashboard_queries.order(:position).preload(:query).map(&:query)
      @statements = []
      @queries.each do |query|
        statement = query.statement.dup
        process_vars(statement, query.data_source)
        @statements << statement
      end
      @bind_vars ||= []

      @smart_vars = {}
      @sql_errors = []
      @data_sources = @queries.map { |q| Blazer.data_sources[q.data_source] }.uniq
      @bind_vars.each do |var|
        @data_sources.each do |data_source|
          smart_var, error = parse_smart_variables(var, data_source)
          ((@smart_vars[var] ||= []).concat(smart_var)).uniq! if smart_var
          @sql_errors << error if error
        end
      end

      add_cohort_analysis_vars if @queries.any?(&:cohort_analysis?)
    end

    def edit
    end

    def update
      if update_dashboard(@dashboard)
        redirect_to dashboard_path(@dashboard, variable_params(@dashboard))
      else
        render_errors @dashboard
      end
    end

    def destroy
      @dashboard.destroy
      redirect_to root_path
    end

    def refresh
      @dashboard.queries.each do |query|
        data_source = Blazer.data_sources[query.data_source]
        statement = query.statement.dup
        process_vars(statement, query.data_source)
        Blazer.transform_statement.call(data_source, statement) if Blazer.transform_statement
        data_source.clear_cache(statement)
      end
      redirect_to dashboard_path(@dashboard, variable_params(@dashboard))
    end

    private

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
