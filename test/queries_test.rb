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

  def test_create_error
    post blazer.queries_path, params: {query: {name: "Test", statement: "", data_source: "main"}}
    assert_response :unprocessable_entity
    assert_match /Statement can(&#39;|’)t be blank/, response.body
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

  def test_refresh
    query = create_query
    post blazer.refresh_query_path(query)
    assert_response :redirect
  end

  def test_variables_time
    query = create_query(statement: "SELECT {created_at}")
    get blazer.query_path(query)
    assert_response :success
    assert_match "singleDatePicker", response.body
  end

  def test_variables_time_range
    query = create_query(statement: "SELECT {start_time}, {end_time}")
    get blazer.query_path(query)
    assert_response :success
    assert_match "daterangepicker", response.body
  end

  def test_variable_defaults
    query = create_query(statement: "SELECT {default_var}")
    get blazer.query_path(query)
    assert_response :success
    assert_match %{value="default_value"}, response.body
  end

  def test_variables_id
    query = create_query(statement: "SELECT {id}")
    get blazer.query_path(query), params: {id: 123}
    assert_response :success
    assert_match %!"variables":{"id":"123"}!, response.body
  end

  def test_smart_variables
    query = create_query(statement: "SELECT {period}")
    get blazer.query_path(query)
    assert_response :success
    assert_match "day", response.body
    assert_match "week", response.body
    assert_match "month", response.body
  end

  def test_linked_columns
    run_query "SELECT 123 AS user_id"
    assert_match "/admin/users/123", response.body
  end

  def test_smart_columns
    run_query "SELECT 0 AS status"
    assert_match "Active", response.body
  end

  def test_csv
    run_query("SELECT 1 AS id, 'Chicago' AS city", format: "csv")
    assert_equal "id,city\n1,Chicago\n", response.body
    assert_equal "attachment; filename=\"query.csv\"; filename*=UTF-8''query.csv", response.headers["Content-Disposition"]
    assert_equal "text/csv; charset=utf-8", response.headers["Content-Type"]
  end

  def test_csv_query
    query = create_query(name: "All Cities", statement: "SELECT 1 AS id, 'Chicago' AS city")
    run_query(query.statement, format: "csv", query_id: query.id)
    assert_equal "id,city\n1,Chicago\n", response.body
    assert_equal "attachment; filename=\"all-cities.csv\"; filename*=UTF-8''all-cities.csv", response.headers["Content-Disposition"]
    assert_equal "text/csv; charset=utf-8", response.headers["Content-Type"]
  end

  def test_csv_query_variables
    query = create_query(name: "Cities", statement: "SELECT 1 AS id, {name} AS city")
    run_query(query.statement, format: "csv", query_id: query.id, variables: {name: "Chicago"})
    assert_equal "id,city\n1,Chicago\n", response.body
    assert_equal "attachment; filename=\"cities.csv\"; filename*=UTF-8''cities.csv", response.headers["Content-Disposition"]
    assert_equal "text/csv; charset=utf-8", response.headers["Content-Type"]
  end

  def test_url
    run_query "SELECT 'http://localhost:3000/'"
    assert_match %{<a target="_blank" href="http://localhost:3000/">http://localhost:3000/</a>}, response.body
  end

  def test_images_default
    run_query("SELECT 'http://localhost:3000/image.png'")
    refute_match %{<img referrerpolicy="no-referrer" src="http://localhost:3000/image.png" />}, response.body
  end

  def test_images
    Blazer.stub(:images, true) do
      run_query("SELECT 'http://localhost:3000/image.png'")
      assert_match %{<img referrerpolicy="no-referrer" src="http://localhost:3000/image.png" }, response.body
    end
  end

  def test_async
    Blazer.stub(:async, true) do
      perform_enqueued_jobs do
        run_query "SELECT 123"
      end
      assert_match "123", response.body
    end
  end
end
