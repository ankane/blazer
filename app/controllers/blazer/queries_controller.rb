module Blazer
  class QueriesController < BaseController
    before_action :set_query, only: [:show, :edit, :update, :destroy]

    def index
      @queries = Blazer::Query.order(:name)
      @queries = @queries.includes(:creator) if Blazer.user_class
      @trending_queries = Blazer::Audit.group(:query_id).where("created_at > ?", 2.days.ago).having("COUNT(DISTINCT user_id) >= 3").uniq.count(:user_id)
      @checks = Blazer::Check.group(:blazer_query_id).count
    end

    def new
      @query = Blazer::Query.new(statement: params[:statement])
    end

    def create
      @query = Blazer::Query.new(query_params)
      @query.creator = current_user if respond_to?(:current_user) && Blazer.user_class

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
      @bind_vars.each do |var|
        query = Blazer.smart_variables[var]
        if query
          rows, error = Blazer.run_statement(query)
          @smart_vars[var] = rows.map { |v| v.values.reverse }
          @sql_errors << error if error
        end
      end
    end

    def edit
    end

    def run
      @statement = params[:statement]
      process_vars(@statement)
      @only_chart = params[:only_chart]

      if @success
        @query = Query.find_by(id: params[:query_id]) if params[:query_id]

        # audit
        if Blazer.audit
          audit = Blazer::Audit.new(statement: @statement)
          audit.query = @query
          audit.user = current_user if respond_to?(:current_user) && Blazer.user_class
          audit.save!
        end

        @rows, @error = Blazer.run_statement(@statement)

        if @query && !@error.to_s.include?("canceling statement due to statement timeout")
          @query.blazer_checks.each do |check|
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

        @min_width_types = (@rows.first || {}).select { |k, v| v.is_a?(Time) || v.is_a?(String) || Blazer.smart_columns[k] }.keys

        @boom = {}
        @columns.keys.each do |key|
          query = Blazer.smart_columns[key]
          if query
            values = @rows.map { |r| r[key] }.compact.uniq
            rows, error = Blazer.run_statement(ActiveRecord::Base.send(:sanitize_sql_array, [query.sub("{value}", "(?)"), values]))
            @boom[key] = Hash[rows.map(&:values)]
          end
        end

        @linked_columns = Blazer.linked_columns
      end

      respond_to do |format|
        format.html do
          render layout: false
        end
        format.csv do
          send_data csv_data(@rows), type: "text/csv; charset=utf-8; header=present", disposition: "attachment; filename=\"#{@query ? @query.name.parameterize : 'query'}.csv\""
        end
      end
    end

    def update
      if @query.update(query_params)
        redirect_to query_path(@query, variable_params)
      else
        render :edit
      end
    end

    def destroy
      @query.destroy
      redirect_to root_url
    end

    private

    def set_query
      @query = Blazer::Query.find(params[:id].to_s.split("-").first)
    end

    def query_params
      params.require(:query).permit(:name, :description, :statement)
    end

    def csv_data(rows)
      CSV.generate do |csv|
        if rows.any?
          csv << rows.first.keys
        end
        rows.each do |row|
          csv << row.values
        end
      end
    end
  end
end
