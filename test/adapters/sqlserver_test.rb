require_relative "../test_helper"

class SqlserverTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "sqlserver"
  end
end
