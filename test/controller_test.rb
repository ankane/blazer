require_relative "test_helper"

class ControllerTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Audit.delete_all
    Blazer::Query.delete_all
  end

  def test_index
    get blazer.root_path
    assert_response :success
  end

  def test_create_query
    post blazer.queries_path, params: {query: {name: "Test", statement: "SELECT 1", data_source: "main"}}
    assert_response :redirect

    query = Blazer::Query.last
    get blazer.query_path(query)
    assert_response :success

    post blazer.run_queries_path, params: {statement: query.statement, data_source: query.data_source, query_id: query.id}, xhr: true
    assert_response :success
    audit = Blazer::Audit.last
    assert_equal query.id, audit.query_id
    assert_equal query.statement, audit.statement
    assert_equal query.data_source, audit.data_source
  end

  # TODO switch to postgres and check table names
  def test_tables
    get blazer.tables_queries_path(data_source: "main")
    assert_response :success
  end
end
