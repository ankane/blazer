require_relative "../test_helper"

class SqliteTest < ActionDispatch::IntegrationTest
  def test_run
    run_query "SELECT 1", data_source: "sqlite"
  end

  def test_tables
    get blazer.tables_queries_path(data_source: "sqlite")
    assert_response :success
    assert_empty JSON.parse(response.body)
  end
end
