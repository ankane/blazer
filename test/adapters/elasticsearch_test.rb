require_relative "../test_helper"

class ElasticsearchTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "elasticsearch"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
