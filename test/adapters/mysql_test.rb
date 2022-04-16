require_relative "../test_helper"

class MysqlTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "mysql"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
