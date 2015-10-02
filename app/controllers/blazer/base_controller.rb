module Blazer
  class BaseController < ApplicationController
    # skip all filters
    skip_filter *_process_action_callbacks.map(&:filter)

    protect_from_forgery with: :exception

    if ENV["BLAZER_PASSWORD"]
      http_basic_authenticate_with name: ENV["BLAZER_USERNAME"], password: ENV["BLAZER_PASSWORD"]
    end

    layout "blazer/application"

    before_action :ensure_database_url

    private

    def ensure_database_url
      render text: "BLAZER_DATABASE_URL required" if !ENV["BLAZER_DATABASE_URL"] && !Rails.env.development?
    end

    def process_vars(statement)
      (@bind_vars ||= []).concat(extract_vars(statement)).uniq!
      @success = @bind_vars.all? { |v| params[v] }

      if @success
        @bind_vars.each do |var|
          value = params[var].presence
          value = value.to_i if value.to_i.to_s == value
          if var.end_with?("_at")
            value = Blazer.time_zone.parse(value) rescue nil
          end
          statement.gsub!("{#{var}}", ActiveRecord::Base.connection.quote(value))
        end
      end
    end

    def extract_vars(statement)
      statement.scan(/\{.*?\}/).map { |v| v[1...-1] }.uniq
    end
    helper_method :extract_vars

    def variable_params
      params.except(:controller, :action, :id, :host, :query, :table_names, :authenticity_token, :utf8, :_method, :commit, :statement, :data_source)
    end
    helper_method :variable_params
  end
end
