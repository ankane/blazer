require_relative "../test_helper"

class PostgresqlTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "postgresql"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
