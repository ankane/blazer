require "bundler/setup"
require "combustion"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDERR : nil)

Combustion.path = "test/internal"
Combustion.initialize! :active_record, :action_controller, :action_mailer, :sprockets do
  config.action_controller.logger = logger
  config.active_record.logger = logger
end

ActiveSupport.on_load(:active_record) do
  connection.execute("CREATE SCHEMA IF NOT EXISTS uploads")
end

class ActionDispatch::IntegrationTest
  def run_query(statement, **params)
    post blazer.run_queries_path, params: {statement: statement, data_source: "main"}.merge(params), xhr: true
    assert_response :success
  end

  def create_query(statement: "SELECT 1")
    Blazer::Query.create!(statement: statement, data_source: "main", status: "active")
  end
end
