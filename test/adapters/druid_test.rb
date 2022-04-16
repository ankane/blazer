require_relative "../test_helper"

class DruidTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "druid"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
