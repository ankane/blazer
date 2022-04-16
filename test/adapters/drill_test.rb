require_relative "../test_helper"

class DrillTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "drill"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
