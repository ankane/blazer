module Blazer
  class BaseController < ApplicationController
    # skip filters
    filters = _process_action_callbacks.map(&:filter) - [:activate_authlogic]
    skip_before_action(*filters, raise: false)
    skip_after_action(*filters, raise: false)
    skip_around_action(*filters, raise: false)

    clear_helpers

    protect_from_forgery with: :exception

    if ENV["BLAZER_PASSWORD"]
      http_basic_authenticate_with name: ENV["BLAZER_USERNAME"], password: ENV["BLAZER_PASSWORD"]
    end

    if Blazer.settings["before_action"]
      raise Blazer::Error, "The docs for protecting Blazer with a custom before_action had an incorrect example from August 2017 to June 2018. The example method had a boolean return value. However, you must render or redirect if a user is unauthorized rather than return a falsy value. Double check that your before_action works correctly for unauthorized users (if it worked when added, there should be no issue). Then, change before_action to before_action_method in config/blazer.yml."
    end

    if Blazer.before_action
      before_action Blazer.before_action.to_sym
    end

    if Blazer.override_csp
      after_action do
        response.headers['Content-Security-Policy'] = "default-src 'self' https: 'unsafe-inline' 'unsafe-eval' data:"
      end
    end

    layout "blazer/application"

    private

      def process_vars(statement, data_source)
        (@bind_vars ||= []).concat(Blazer.extract_vars(statement)).uniq!
        @bind_vars.each do |var|
          params[var] ||= Blazer.data_sources[data_source].variable_defaults[var]
        end
        @success = @bind_vars.all? { |v| params[v] }

        if @success
          @bind_vars.each do |var|
            value = params[var].presence
            if value
              if ["start_time", "end_time"].include?(var)
                value = value.to_s.gsub(" ", "+") # fix for Quip bug
              end

              if var.end_with?("_at")
                begin
                  value = Blazer.time_zone.parse(value)
                rescue
                  # do nothing
                end
              end

              if value =~ /\A\d+\z/
                value = value.to_i
              elsif value =~ /\A\d+\.\d+\z/
                value = value.to_f
              end
            end
            value = Blazer.transform_variable.call(var, value) if Blazer.transform_variable
            statement.gsub!("{#{var}}", ActiveRecord::Base.connection.quote(value))
          end
        end
      end

      def add_cohort_analysis_vars
        @bind_vars << "cohort_period" unless @bind_vars.include?("cohort_period")
        @smart_vars["cohort_period"] = ["day", "week", "month"]
        params[:cohort_period] ||= "week"
      end

      def parse_smart_variables(var, data_source)
        smart_var_data_source =
          ([data_source] + Array(data_source.settings["inherit_smart_settings"]).map { |ds| Blazer.data_sources[ds] }).find { |ds| ds.smart_variables[var] }

        if smart_var_data_source
          query = smart_var_data_source.smart_variables[var]

          if query.is_a? Hash
            smart_var = query.map { |k,v| [v, k] }
          elsif query.is_a? Array
            smart_var = query.map { |v| [v, v] }
          elsif query
            result = smart_var_data_source.run_statement(query)
            smart_var = result.rows.map { |v| v.reverse }
            error = result.error if result.error
          end
        end

        [smart_var, error]
      end

      # don't pass to url helpers
      #
      # some are dangerous when passed as symbols
      # root_url({host: "evilsite.com"})
      #
      # certain ones (like host) only affect *_url and not *_path
      #
      # when permitted parameters are passed in Rails 6,
      # they appear to be added as GET parameters
      # root_url(params.permit(:host))
      UNPERMITTED_KEYS = [:controller, :action, :id, :host, :query, :dashboard, :query_id, :query_ids, :table_names, :authenticity_token, :utf8, :_method, :commit, :statement, :data_source, :name, :fork_query_id, :blazer, :run_id, :script_name, :original_script_name]

      # remove unpermitted keys from both params and permitted keys for better sleep
      def variable_params(resource)
        permitted_keys = resource.variables - UNPERMITTED_KEYS.map(&:to_s)
        params.except(*UNPERMITTED_KEYS).slice(*permitted_keys).permit!
      end
      helper_method :variable_params

      def blazer_user
        send(Blazer.user_method) if Blazer.user_method && respond_to?(Blazer.user_method, true)
      end
      helper_method :blazer_user

      def render_errors(resource)
        @errors = resource.errors
        action = resource.persisted? ? :edit : :new
        render action, status: :unprocessable_entity
      end

      # do not inherit from ApplicationController - #120
      def default_url_options
        {}
      end
  end
end
