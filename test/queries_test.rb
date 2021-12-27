require_relative "test_helper"

class QueriesTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Audit.delete_all
    Blazer::Query.delete_all
  end

  def test_index
    get blazer.root_path
    assert_response :success
  end

  def test_create
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

  def test_destroy
    query = create_query
    delete blazer.query_path(query)
    assert_response :redirect
  end

  def test_rollback
    create_query
    run_query "DELETE FROM blazer_queries"
    assert_equal 1, Blazer::Query.count
  end

  def test_tables
    get blazer.tables_queries_path(data_source: "main")
    assert_response :success
    tables = JSON.parse(response.body).map { |v| v["table"] }
    assert_includes tables, "blazer_queries"
  end

  def test_schema
    get blazer.schema_queries_path(data_source: "main")
    assert_response :success
  end

  def test_docs
    get blazer.docs_queries_path(data_source: "main")
    assert_response :success
  end

  def test_linked_columns
    run_query "SELECT 123 AS user_id"
    assert_match "/admin/users/123", response.body
  end

  def test_smart_columns
    run_query "SELECT 0 AS status"
    assert_match "Active", response.body
  end
end
