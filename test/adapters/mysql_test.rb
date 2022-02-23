require_relative "../test_helper"

class MysqlTest < ActionDispatch::IntegrationTest
  def test_run
    run_query "SELECT 12345", data_source: "mysql"
  end

  def test_binary_data
    # 746573745F636F6E74656E74 represents "test_content" with "F6" being invalid binary data
    run_query 'SELECT UNHEX("F6746573745F636F6E74656E74"), 54321', data_source: "mysql"
    assert_match "54321", response.body
    assert_match "test_content", response.body
  end

  def test_tables
    get blazer.tables_queries_path(data_source: "mysql")
    assert_response :success
    assert_empty JSON.parse(response.body)
  end
end
