module Blazer
  class BaseController < ApplicationController
    # skip all filters
    filters = _process_action_callbacks.map(&:filter)
    if Rails::VERSION::MAJOR >= 5
      skip_before_action(*filters, raise: false)
      skip_after_action(*filters, raise: false)
      skip_around_action(*filters, raise: false)
    else
      skip_action_callback *filters
    end

    protect_from_forgery with: :exception

    if ENV["BLAZER_PASSWORD"]
      http_basic_authenticate_with name: ENV["BLAZER_USERNAME"], password: ENV["BLAZER_PASSWORD"]
    end

    if Blazer.before_action
      before_action Blazer.before_action
    end

    before_action :set_gon

    layout "blazer/application"

    private

    def process_vars(statement, data_source)
      (@bind_vars ||= []).concat(extract_vars(statement)).uniq!
      @bind_vars.each do |var|
        params[var] ||= Blazer.data_sources[data_source].variable_defaults[var]
      end
      @success = @bind_vars.all? { |v| params[v] }

      if @success
        @bind_vars.each do |var|
          value = params[var].presence
          if value
            if value =~ /\A\d+\z/
              value = value.to_i
            elsif value =~ /\A\d+\.\d+\z/
              value = value.to_f
            end
          end
          if var.end_with?("_at")
            value = Blazer.time_zone.parse(value) rescue nil
          end
          value.gsub!(" ", "+") if value.is_a?(String) && ["start_time", "end_time"].include?(var) # fix for Quip bug
          statement.gsub!("{#{var}}", ActiveRecord::Base.connection.quote(value))
        end
      end
    end

    def extract_vars(statement)
      # strip commented out lines
      # and regex {1} or {1,2}
      statement.gsub(/\-\-.+/, "").gsub(/\/\*.+\*\//m, "").scan(/\{\w*?\}/i).map { |v| v[1...-1] }.reject { |v| /\A\d+(\,\d+)?\z/.match(v) || v.empty? }.uniq
    end
    helper_method :extract_vars

    def variable_params
      params.except(:controller, :action, :id, :host, :query, :dashboard, :query_id, :query_ids, :table_names, :authenticity_token, :utf8, :_method, :commit, :statement, :data_source, :name, :fork_query_id, :blazer).permit!
    end
    helper_method :variable_params

    def blazer_user
      send(Blazer.user_method) if Blazer.user_method && respond_to?(Blazer.user_method)
    end
    helper_method :blazer_user

    def set_gon
      gon.mapbox_access_token = ENV["MAPBOX_ACCESS_TOKEN"]
      gon.images = Blazer.images
      gon.time_zone = Blazer.time_zone.tzinfo.name
    end
  end
end
