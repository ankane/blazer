module Blazer
  class QueriesController < BaseController
    before_action :set_query, only: [:show, :edit, :update, :destroy, :refresh]

    def home
      set_queries(1000)
      @dashboards =
        Blazer::Dashboard.order(:name).map do |d|
          {
            name: "<strong>#{view_context.link_to(d.name, d)}</strong>",
            creator: blazer_user && d.try(:creator) == blazer_user ? "You" : d.try(:creator).try(Blazer.user_name),
            hide: d.name.gsub(/\s+/, ""),
            vars: nil
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
        render :new
      end
    end

    def show
      @statement = @query.statement.dup
      process_vars(@statement, @query.data_source)

      @smart_vars = {}
      @sql_errors = []
      data_source = Blazer.data_sources[@query.data_source]
      @bind_vars.each do |var|
        query = data_source.smart_variables[var]
        if query
          columns, rows, error, cached_at = data_source.run_statement(query)
          @smart_vars[var] = rows.map { |v| v.reverse }
          @sql_errors << error if error
        end
      end

      Blazer.transform_statement.call(data_source, @statement) if Blazer.transform_statement
    end

    def edit
    end

    def run
      raise "Not allowed" if Blazer.async

      run_query = Blazer::RunQuery.new(params.permit(:statement, :data_source, :only_chart, :query_id, :check).to_unsafe_hash, blazer_user)

      run_query.assigns.each do |k, v|
        instance_variable_set(:"@#{k}", v)
      end

      respond_to do |format|
        format.html do
          render layout: false
        end
        format.csv do
          send_data csv_data(@data_source, @columns, @rows), type: "text/csv; charset=utf-8; header=present", disposition: "attachment; filename=\"#{@query.try(:name).try(:parameterize).presence || 'query'}.csv\""
        end
      end
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
        render :edit
      end
    end

    def destroy
      @query.destroy if @query.editable?(blazer_user)
      redirect_to root_url
    end

    def tables
      @tables = Blazer.data_sources[params[:data_source]].tables
      render partial: "tables", layout: false
    end

    private

    def set_queries(limit = nil)
      @my_queries =
        if limit && blazer_user
          favorite_query_ids = Blazer::Audit.where(user_id: blazer_user.id).where("created_at > ?", 30.days.ago).where("query_id IS NOT NULL").group(:query_id).order("count_all desc").count.keys
          queries = Blazer::Query.named.where(id: favorite_query_ids)
          queries = queries.includes(:creator) if Blazer.user_class
          queries = queries.index_by(&:id)
          favorite_query_ids.map { |query_id| queries[query_id] }.compact
        else
          []
        end

      @queries = Blazer::Query.named.order(:name)
      @queries = @queries.where("id NOT IN (?)", @my_queries.map(&:id)) if @my_queries.any?
      @queries = @queries.includes(:creator) if Blazer.user_class
      @queries = @queries.limit(limit) if limit

      @queries =
        (@my_queries + @queries).map do |q|
          {
            id: q.id,
            name: view_context.link_to(q.name, q),
            creator: blazer_user && q.try(:creator) == blazer_user ? "You" : q.try(:creator).try(Blazer.user_name),
            hide: q.name.gsub(/\s+/, ""),
            vars: extract_vars(q.statement).join(", ")
          }
        end
    end

    def set_query
      @query = Blazer::Query.find(params[:id].to_s.split("-").first)
    end

    def query_params
      params.require(:query).permit(:name, :description, :statement, :data_source)
    end

    def csv_data(data_source, columns, rows)
      CSV.generate do |csv|
        csv << columns
        rows.each do |row|
          csv << row.each_with_index.map { |v, i| v.is_a?(Time) ? blazer_time_value(data_source, columns[i], v) : v }
        end
      end
    end

    def blazer_time_value(data_source, k, v)
      # yuck, instance var
      data_source.local_time_suffix.any? { |s| k.ends_with?(s) } ? v.to_s.sub(" UTC", "") : v.in_time_zone(Blazer.time_zone)
    end
    helper_method :blazer_time_value
  end
end
