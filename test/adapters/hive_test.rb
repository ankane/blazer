require_relative "../test_helper"

class HiveTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "hive"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
