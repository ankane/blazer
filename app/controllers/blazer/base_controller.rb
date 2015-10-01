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
  end
end
