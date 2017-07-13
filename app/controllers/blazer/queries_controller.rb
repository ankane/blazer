module Blazer
  class QueriesController < BaseController
    before_action :set_query, only: [:show, :edit, :update, :destroy, :refresh]

    include ::Blazer::QueryRunner

    def home
      if params[:filter] == "dashboards"
        @queries = []
      else
        set_queries(1000)
      end

      if params[:filter] && params[:filter] != "dashboards"
        @dashboards = [] # TODO show my dashboards
      else
        @dashboards = Blazer::Dashboard.order(:name)
        @dashboards = @dashboards.includes(:creator) if Blazer.user_class
      end

      @dashboards =
        @dashboards.map do |d|
          {
            id: d.id,
            name: d.name,
            creator: blazer_user && d.try(:creator) == blazer_user ? "You" : d.try(:creator).try(Blazer.user_name),
            to_param: d.to_param,
            dashboard: true
          }
        end
    end

    def index
      set_queries
      render json: @queries
    end

    def new
      @query = Blazer::Query.new(
        data_source: params[:data_source],
        name: params[:name]
      )
      if params[:fork_query_id]
        @query.statement ||= Blazer::Query.find(params[:fork_query_id]).try(:statement)
      end
    end

    def create
      @query = Blazer::Query.new(query_params)
      @query.creator = blazer_user if @query.respond_to?(:creator)

      if @query.save
        redirect_to query_path(@query, variable_params)
      else
        render_errors @query
      end
    end

    def show
      @statement = @query.statement.dup
      process_vars(@statement, @query.data_source)

      @smart_vars = {}
      @sql_errors = []
      data_source = Blazer.data_sources[@query.data_source]
      @bind_vars.each do |var|
        smart_var, error = parse_smart_variables(var, data_source)
        @smart_vars[var] = smart_var if smart_var
        @sql_errors << error if error
      end

      Blazer.transform_statement.call(data_source, @statement) if Blazer.transform_statement
    end

    def edit
    end

    def run
      run_command(params[:statement])
    end

    def refresh
      data_source = Blazer.data_sources[@query.data_source]
      @statement = @query.statement.dup
      process_vars(@statement, @query.data_source)
      Blazer.transform_statement.call(data_source, @statement) if Blazer.transform_statement
      data_source.clear_cache(@statement)
      redirect_to query_path(@query, variable_params)
    end

    def update
      if params[:commit] == "Fork"
        @query = Blazer::Query.new
        @query.creator = blazer_user if @query.respond_to?(:creator)
      end
      unless @query.editable?(blazer_user)
        @query.errors.add(:base, "Sorry, permission denied")
      end
      if @query.errors.empty? && @query.update(query_params)
        redirect_to query_path(@query, variable_params)
      else
        render_errors @query
      end
    end

    def destroy
      @query.destroy if @query.editable?(blazer_user)
      redirect_to root_url
    end

    def tables
      render json: Blazer.data_sources[params[:data_source]].tables
    end

    def schema
      @schema = Blazer.data_sources[params[:data_source]].schema
    end

    def cancel
      Blazer.data_sources[params[:data_source]].cancel(blazer_run_id)
      render json: {}
    end

    private


  end
end
