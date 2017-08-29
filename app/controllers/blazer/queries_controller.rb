module Blazer
  class QueriesController < BaseController
    before_action :set_query, only: [:show, :edit, :update, :destroy, :refresh]

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
      @statement = params[:statement]
      data_source = params[:data_source]
      process_vars(@statement, data_source)
      @only_chart = params[:only_chart]
      @run_id = blazer_params[:run_id]
      @query = Query.find_by(id: params[:query_id]) if params[:query_id]
      data_source = @query.data_source if @query && @query.data_source
      @data_source = Blazer.data_sources[data_source]

      if @run_id
        @timestamp = blazer_params[:timestamp].to_i

        @result = @data_source.run_results(@run_id)
        @success = !@result.nil?

        if @success
          @data_source.delete_results(@run_id)
          @columns = @result.columns
          @rows = @result.rows
          @error = @result.error
          @just_cached = !@result.error && @result.cached_at.present?
          @cached_at = nil
          params[:data_source] = nil
          render_run
        elsif Time.now > Time.at(@timestamp + (@data_source.timeout || 600).to_i + 5)
          # query lost
          Rails.logger.info "[blazer lost query] #{@run_id}"
          @error = "We lost your query :("
          @rows = []
          @columns = []
          render_run
        else
          continue_run
        end
      elsif @success
        @run_id = blazer_run_id

        options = {user: blazer_user, query: @query, refresh_cache: params[:check], run_id: @run_id, async: Blazer.async}
        if Blazer.async && request.format.symbol != :csv
          result = []
          Blazer::RunStatementJob.perform_async(result, @data_source, @statement, options)
          wait_start = Time.now
          loop do
            sleep(0.02)
            break if result.any? || Time.now - wait_start > 3
          end
          @result = result.first
        else
          @result = Blazer::RunStatement.new.perform(@data_source, @statement, options)
        end

        if @result
          @data_source.delete_results(@run_id) if @run_id

          @columns = @result.columns
          @rows = @result.rows
          @error = @result.error
          @cached_at = @result.cached_at
          @just_cached = @result.just_cached

          render_run
        else
          @timestamp = Time.now.to_i
          continue_run
        end
      else
        render layout: false
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

      def continue_run
        render json: {run_id: @run_id, timestamp: @timestamp}, status: :accepted
      end

      def render_run
        @checks = @query ? @query.checks.order(:id) : []

        @first_row = @rows.first || []
        @column_types = []
        if @rows.any?
          @columns.each_with_index do |column, i|
            @column_types << (
              case @first_row[i]
              when Integer
                "int"
              when Float, BigDecimal
                "float"
              else
                "string-ins"
              end
            )
          end
        end

        @filename = @query.name.parameterize if @query
        @min_width_types = @columns.each_with_index.select { |c, i| @first_row[i].is_a?(Time) || @first_row[i].is_a?(String) || @data_source.smart_columns[c] }.map(&:last)

        @boom = @result.boom if @result

        @linked_columns = @data_source.linked_columns

        @markers = []
        [["latitude", "longitude"], ["lat", "lon"], ["lat", "lng"]].each do |keys|
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

        respond_to do |format|
          Blazer.query_adapters.each do |query_adapter|
            adapter = query_adapter.new(@query, @columns, @rows, @data_source)

            format.send(adapter.format) do
              send(adapter.render_method, *adapter.render_params)
            end

          end
        end
      end

      def set_queries(limit = nil)
        @my_queries =
          if limit && blazer_user && !params[:filter] && Blazer.audit
            queries_by_ids(Blazer::Audit.where(user_id: blazer_user.id).where("created_at > ?", 30.days.ago).where("query_id IS NOT NULL").group(:query_id).order("count_all desc").count.keys)
          else
            []
          end

        @queries = Blazer::Query.named.select(:id, :name, :creator_id, :statement)
        @queries = @queries.includes(:creator) if Blazer.user_class

        if blazer_user && params[:filter] == "mine"
          @queries = @queries.where(creator_id: blazer_user.id).reorder(updated_at: :desc)
        elsif blazer_user && params[:filter] == "viewed" && Blazer.audit
          @queries = queries_by_ids(Blazer::Audit.where(user_id: blazer_user.id).order(created_at: :desc).limit(500).pluck(:query_id).uniq)
        else
          @queries = @queries.where("id NOT IN (?)", @my_queries.map(&:id)) if @my_queries.any?
          @queries = @queries.limit(limit) if limit
          @queries = @queries.order(:name)
        end
        @queries = @queries.to_a

        @more = limit && @queries.size >= limit

        @queries = (@my_queries + @queries).select { |q| !q.name.to_s.start_with?("#") || q.try(:creator).try(:id) == blazer_user.try(:id) }

        @queries =
          @queries.map do |q|
            {
              id: q.id,
              name: q.name,
              creator: blazer_user && q.try(:creator) == blazer_user ? "You" : q.try(:creator).try(Blazer.user_name),
              vars: q.variables.join(", "),
              to_param: q.to_param
            }
          end
      end

      def queries_by_ids(favorite_query_ids)
        queries = Blazer::Query.named.where(id: favorite_query_ids)
        queries = queries.includes(:creator) if Blazer.user_class
        queries = queries.index_by(&:id)
        favorite_query_ids.map { |query_id| queries[query_id] }.compact
      end

      def set_query
        @query = Blazer::Query.find(params[:id].to_s.split("-").first)
      end

      def query_params
        params.require(:query).permit(:name, :description, :statement, :data_source)
      end

      def blazer_params
        params[:blazer] || {}
      end

      def blazer_time_value(data_source, k, v)
        data_source.local_time_suffix.any? { |s| k.ends_with?(s) } ? v.to_s.sub(" UTC", "") : v.in_time_zone(Blazer.time_zone)
      end
      helper_method :blazer_time_value

      def blazer_run_id
        params[:run_id].to_s.gsub(/[^a-z0-9\-]/i, "")
      end
  end
end
