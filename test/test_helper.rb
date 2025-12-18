require "bundler/setup"
require "combustion"
Bundler.require(:default)
require "minitest/autorun"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDERR : nil)

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller, :action_mailer, :active_job do
  config.load_defaults Rails::VERSION::STRING.to_f
  config.action_controller.logger = logger
  config.action_mailer.logger = logger
  config.active_job.logger = logger
  config.active_record.logger = logger
  config.cache_store = :memory_store

  # fixes warning with adapter tests
  config.action_dispatch.show_exceptions = :none
end

Rails.cache.logger = logger

class ActionDispatch::IntegrationTest
  def run_query(statement, format: nil, **params)
    post blazer.run_queries_path(format: format), params: {statement: statement, data_source: "main"}.merge(params), xhr: true
    assert_response :success
  end

  def create_query(statement: "SELECT 1", **attributes)
    Blazer::Query.create!(statement: statement, data_source: "main", status: "active", **attributes)
  end

  def create_check(**attributes)
    Blazer::Check.create!(schedule: "5 minutes", **attributes)
  end

  def postgresql?
    ENV["ADAPTER"].nil?
  end

  def with_option(name, value)
    previous_value = Blazer.send(name)
    begin
      Blazer.send("#{name}=", value)
      yield
    ensure
      Blazer.send("#{name}=", previous_value)
    end
  end
end

require_relative "support/adapter_test"
