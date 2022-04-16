require_relative "../test_helper"

class BigqueryTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "bigquery"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
