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
      @statement = params[:statement]
      data_source = params[:data_source]
      process_vars(@statement, data_source)
      @only_chart = params[:only_chart]

      if @success
        @query = Query.find_by(id: params[:query_id]) if params[:query_id]

        data_source = @query.data_source if @query && @query.data_source
        @data_source = Blazer.data_sources[data_source]

        @columns, @rows, @error, @cached_at, @just_cached = @data_source.run_main_statement(@statement, user: blazer_user, query: @query, refresh_cache: params[:check])

        render_run
      end

      respond_to do |format|
        format.html do
          render layout: false
        end
        format.csv do
          send_data csv_data(@columns, @rows, @data_source), type: "text/csv; charset=utf-8; header=present", disposition: "attachment; filename=\"#{@query.try(:name).try(:parameterize).presence || 'query'}.csv\""
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

    def render_run
      @checks = @query ? @query.checks : []

      @first_row = @rows.first || []
      @column_types = []
      if @rows.any?
        @columns.each_with_index do |column, i|
          @column_types << (
            case @first_row[i]
            when Integer
              "int"
            when Float
              "float"
            else
              "string-ins"
            end
          )
        end
      end

      @filename = @query.name.parameterize if @query
      @min_width_types = @columns.each_with_index.select { |c, i| @first_row[i].is_a?(Time) || @first_row[i].is_a?(String) || @data_source.smart_columns[c] }

      @boom = {}
      @columns.each_with_index do |key, i|
        query = @data_source.smart_columns[key]
        if query
          values = @rows.map { |r| r[i] }.compact.uniq
          columns, rows, error, cached_at = @data_source.run_statement(ActiveRecord::Base.send(:sanitize_sql_array, [query.sub("{value}", "(?)"), values]))
          @boom[key] = Hash[rows.map { |k, v| [k.to_s, v] }]
        end
      end

      @linked_columns = @data_source.linked_columns

      @markers = []
      [["latitude", "longitude"], ["lat", "lon"]].each do |keys|
        lat_index = @columns.index(keys.first)
        lon_index = @columns.index(keys.last)
        if lat_index && lon_index
          @markers =
            @rows.select do |r|
              r[lat_index] && r[lon_index]
            end.map do |r|
              {
                title: r.each_with_index.map{ |v, i| i == lat_index || i == lon_index ? nil : "<strong>#{@columns[i]}:</strong> #{v}" }.compact.join("<br />").truncate(140),
                latitude: r[lat_index],
                longitude: r[lon_index]
              }
            end
        end
      end
    end

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

    def csv_data(columns, rows, data_source)
      CSV.generate do |csv|
        csv << columns
        rows.each do |row|
          csv << row.each_with_index.map { |v, i| v.is_a?(Time) ? blazer_time_value(data_source, columns[i], v) : v }
        end
      end
    end

    def blazer_time_value(data_source, k, v)
      data_source.local_time_suffix.any? { |s| k.ends_with?(s) } ? v.to_s.sub(" UTC", "") : v.in_time_zone(Blazer.time_zone)
    end
    helper_method :blazer_time_value
  end
end
