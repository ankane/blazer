module Blazer
  class QueriesController < BaseController
    before_action :set_query, only: [:show, :edit, :update, :destroy, :refresh]

    def home
      set_queries(1000)
    end

    def index
      set_queries
      render partial: "index", layout: false
    end

    def new
      @query = Blazer::Query.new(
        statement: params[:statement],
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
      process_vars(@statement)

      @smart_vars = {}
      @sql_errors = []
      data_source = Blazer.data_sources[@query.data_source]
      @bind_vars.each do |var|
        query = data_source.smart_variables[var]
        if query
          rows, error, cached_at = data_source.run_statement(query)
          @smart_vars[var] = rows.map { |v| v.values.reverse }
          @sql_errors << error if error
        end
      end

      Blazer.transform_statement.call(data_source, @statement) if Blazer.transform_statement
    end

    def edit
    end

    def run
      @statement = params[:statement]
      process_vars(@statement)
      @only_chart = params[:only_chart]

      if @success
        @query = Query.find_by(id: params[:query_id]) if params[:query_id]

        data_source = params[:data_source]
        data_source = @query.data_source if @query && @query.data_source
        @data_source = Blazer.data_sources[data_source]
        Blazer.transform_statement.call(@data_source, @statement) if Blazer.transform_statement

        # audit
        if Blazer.audit
          audit = Blazer::Audit.new(statement: @statement)
          audit.query = @query
          audit.data_source = data_source
          audit.user = blazer_user
          audit.save!
        end

        @rows, @error, @cached_at = @data_source.run_statement(@statement, user: blazer_user, query: @query, refresh_cache: params[:check])

        if @query && @error != Blazer::TIMEOUT_MESSAGE
          @query.checks.each do |check|
            check.update_state(@rows, @error)
          end
        end

        @columns = {}
        if @rows.any?
          @rows.first.each do |key, value|
            @columns[key] =
              case value
              when Integer
                "int"
              when Float
                "float"
              else
                "string-ins"
              end
          end
        end

        @filename = @query.name.parameterize if @query

        @min_width_types = (@rows.first || {}).select { |k, v| v.is_a?(Time) || v.is_a?(String) || @data_source.smart_columns[k] }.keys

        @boom = {}
        @columns.keys.each do |key|
          query = @data_source.smart_columns[key]
          if query
            values = @rows.map { |r| r[key] }.compact.uniq
            rows, error, cached_at = @data_source.run_statement(ActiveRecord::Base.send(:sanitize_sql_array, [query.sub("{value}", "(?)"), values]))
            @boom[key] = Hash[rows.map(&:values).map { |k, v| [k.to_s, v] }]
          end
        end

        @linked_columns = @data_source.linked_columns

        @markers = []
        [["latitude", "longitude"], ["lat", "lon"]].each do |keys|
          if (keys - (@rows.first || {}).keys).empty?
            @markers =
              @rows.select do |r|
                r[keys.first] && r[keys.last]
              end.map do |r|
                {
                  title: r.except(*keys).map{ |k, v| "<strong>#{k}:</strong> #{v}" }.join("<br />").truncate(140),
                  latitude: r[keys.first],
                  longitude: r[keys.last]
                }
              end
          end
        end
      end

      respond_to do |format|
        format.html do
          render layout: false
        end
        format.csv do
          send_data csv_data(@rows), type: "text/csv; charset=utf-8; header=present", disposition: "attachment; filename=\"#{@query.try(:name).try(:parameterize).presence || 'query'}.csv\""
        end
      end
    end

    def refresh
      data_source = Blazer.data_sources[@query.data_source]
      @statement = @query.statement.dup
      process_vars(@statement)
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
      @tables = Blazer.data_sources[params[:data_source]].tables.keys
      render partial: "tables", layout: false
    end

    private

    def set_queries(limit = nil)
      @my_queries =
        if blazer_user
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
      @trending_queries = Blazer::Audit.group(:query_id).where("created_at > ?", 2.days.ago).having("COUNT(DISTINCT user_id) >= 3").uniq.count(:user_id)
      @checks = Blazer::Check.group(:query_id).count
      @dashboards = Blazer::Dashboard.order(:name)
    end

    def set_query
      @query = Blazer::Query.find(params[:id].to_s.split("-").first)
    end

    def query_params
      params.require(:query).permit(:name, :description, :statement, :data_source)
    end

    def csv_data(rows)
      CSV.generate do |csv|
        if rows.any?
          csv << rows.first.keys
        end
        rows.each do |row|
          csv << row.map { |k, v| v.is_a?(Time) ? blazer_time_value(k, v) : v }
        end
      end
    end

    def blazer_time_value(k, v)
      # yuck, instance var
      @data_source.local_time_suffix.any? { |s| k.ends_with?(s) } ? v.to_s.sub(" UTC", "") : v.in_time_zone(Blazer.time_zone)
    end
    helper_method :blazer_time_value
  end
end
