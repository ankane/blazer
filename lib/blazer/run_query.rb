module Blazer
  class RunQuery
    include ProcessVars

    def initialize(params, blazer_user)
      params = HashWithIndifferentAccess.new(params)

      @statement = params[:statement]
      data_source = params[:data_source]
      process_vars(@statement, data_source)
      @only_chart = params[:only_chart]

      if @success
        @query = Query.find_by(id: params[:query_id]) if params[:query_id]

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

        start_time = Time.now
        @columns, @rows, @error, @cached_at, @just_cached = @data_source.run_statement(@statement, user: blazer_user, query: @query, refresh_cache: params[:check], with_just_cached: true)
        duration = Time.now - start_time

        if Blazer.audit
          audit.duration = duration if audit.respond_to?(:duration=)
          audit.error = @error if audit.respond_to?(:error=)
          audit.timed_out = @error == Blazer::TIMEOUT_MESSAGE if audit.respond_to?(:timed_out=)
          audit.cached = @cached_at.present? if audit.respond_to?(:cached=)
          if !@cached_at && duration >= 10
            audit.cost = @data_source.cost(@statement) if audit.respond_to?(:cost=)
          end
          audit.save! if audit.changed?
        end

        if @query && @error != Blazer::TIMEOUT_MESSAGE
          @query.checks.each do |check|
            check.update_state(@rows, @error)
          end
        end

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
    end

    def assigns
      Hash[instance_variables.map { |k| [k.to_s.sub("@", ""), instance_variable_get(k)] }]
    end

    def render
      Blazer::QueriesController.render :run, layout: false, assigns: assigns
    end
  end
end
