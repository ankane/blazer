require_relative "../test_helper"

class SnowflakeTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "snowflake"
  end
end
