require_relative "../test_helper"

class ElasticsearchTest < ActionDispatch::IntegrationTest
  def test_run
    skip "broken"
    run_query "SELECT 1", data_source: "elasticsearch"
  end

  def test_tables
    skip "broken"
    get blazer.tables_queries_path(data_source: "elasticsearch")
    assert_response :success
    assert_kind_of Array, JSON.parse(response.body)
  end
end
