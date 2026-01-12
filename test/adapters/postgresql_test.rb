require_relative "../test_helper"

class PostgresqlTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "postgresql"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end

  def test_audit
    assert_audit "SELECT $1 AS hello\n\n[\"world\"]", "SELECT {var} AS hello", var: "world"
  end

  def test_string
    assert_result [{"hello" => "world"}], "SELECT {var} AS hello", var: "world"
  end

  def test_integer
    assert_result [{"hello" => "1"}], "SELECT {var} AS hello", var: "1"
  end

  def test_leading_zeros
    assert_result [{"hello" => "0123"}], "SELECT {var} AS hello", var: "0123"
  end

  def test_float
    assert_result [{"hello" => "1.5"}], "SELECT {var} AS hello", var: "1.5"
  end

  def test_time
    assert_result [{"hello" => "2022-01-01 08:00:00"}], "SELECT {created_at} AS hello", created_at: "2022-01-01 08:00:00"
  end

  def test_nil
    assert_result [{"hello" => nil}], "SELECT {var} AS hello", var: ""
  end

  def test_single_quote
    assert_result [{"hello" => "'"}], "SELECT {var} AS hello", var: "'"
  end

  def test_double_quote
    assert_result [{"hello" => '"'}], "SELECT {var} AS hello", var: '"'
  end

  def test_backslash
    assert_result [{"hello" => "\\"}], "SELECT {var} AS hello", var: "\\"
  end

  def test_multiple_variables
    assert_result [{"c1" => "one", "c2" => "two", "c3" => "one"}], "SELECT {var} AS c1, {var2} AS c2, {var} AS c3", var: "one", var2: "two"
  end

  def test_bad_position
    assert_bad_position "SELECT 'world' AS {var}", var: "hello"
  end

  def test_bad_position_before
    assert_error "syntax error at or near \"SELECT$1\"", "SELECT{var}", var: "world"
  end

  def test_bad_position_after
    assert_error "syntax error at or near \"456\"\nLINE 1: SELECT $1 456", "SELECT {var}456", var: "world"
    assert_equal "SELECT $1 456\n\n[\"world\"]", Blazer::Audit.last.statement
  end

  def test_quoted
    assert_error "could not determine data type of parameter $1", "SELECT '{var}' AS hello", var: "world"
  end

  def test_binary_output
    assert_result [{"bytea" => "\\x68656c6c6f"}], "SELECT 'hello'::bytea"
  end

  def test_json_output
    assert_result [{"json" => '{"hello": "world"}'}], %!SELECT '{"hello": "world"}'::json!
  end

  def test_jsonb_output
    assert_result [{"jsonb" => '{"hello": "world"}'}], %!SELECT '{"hello": "world"}'::jsonb!
  end

  # Materialized view tests

  def test_tables_includes_materialized_views
    table_list = tables
    table_names = table_list.map { |t| t.is_a?(Hash) ? t["table"] : t }

    assert_includes table_names, "test_matview_simple", "Simple matview should be in tables list"
    assert_includes table_names, "test_matview_complex", "Complex matview should be in tables list"
  end

  def test_tables_matviews_have_correct_format
    table_list = tables
    matview = table_list.find { |t| t.is_a?(Hash) && t["table"] == "test_matview_simple" }

    assert matview, "Materialized view should be in tables list"
    assert matview["value"], "Materialized view should have quoted value"
    assert_equal "\"test_matview_simple\"", matview["value"]
  end

  def test_schema_includes_materialized_views
    get blazer.schema_queries_path(data_source: data_source)
    assert_response :success

    assert_match(/test_matview_simple/, response.body, "Simple matview should be in schema page")
    assert_match(/test_matview_complex/, response.body, "Complex matview should be in schema page")
  end

  def test_schema_matview_columns
    schema_data = Blazer.data_sources[data_source].schema

    simple_matview = schema_data.find { |t| t[:table] == "test_matview_simple" }
    assert simple_matview, "Simple matview should be in schema data"

    column_names = simple_matview[:columns].map { |c| c[:name] }
    assert_includes column_names, "id"
    assert_includes column_names, "name"
    assert_includes column_names, "created_at"
  end

  def test_schema_matview_complex_columns
    schema_data = Blazer.data_sources[data_source].schema

    complex_matview = schema_data.find { |t| t[:table] == "test_matview_complex" }
    assert complex_matview, "Complex matview should be in schema data"

    column_names = complex_matview[:columns].map { |c| c[:name] }
    assert_includes column_names, "id"
    assert_includes column_names, "name"
    assert_includes column_names, "value"
    assert_includes column_names, "active"
    assert_includes column_names, "metadata"
    assert_includes column_names, "created_at"
    assert_includes column_names, "updated_at"
  end

  def test_query_against_matview
    run_statement("SELECT * FROM test_matview_simple")
    # If we get here without error, the query succeeded
  end

  def test_matview_query_returns_data
    result = run_statement("SELECT COUNT(*) as cnt FROM test_matview_simple")
    assert_equal [{"cnt" => "3"}], result
  end

  private

  def setup_materialized_views
    connection = ActiveRecord::Base.connection

    # Insert test data if not exists
    unless connection.select_value("SELECT COUNT(*) FROM matview_source").to_i > 0
      connection.execute(<<~SQL)
        INSERT INTO matview_source (name, value, active, metadata, created_at, updated_at)
        VALUES
          ('test1', 100, true, '{"key": "value1"}', NOW(), NOW()),
          ('test2', 200, false, '{"key": "value2"}', NOW(), NOW()),
          ('test3', 300, true, '{"key": "value3"}', NOW(), NOW())
      SQL
    end

    # Create simple materialized view if not exists
    unless connection.select_value("SELECT COUNT(*) FROM pg_matviews WHERE matviewname = 'test_matview_simple'").to_i > 0
      connection.execute(<<~SQL)
        CREATE MATERIALIZED VIEW test_matview_simple AS
        SELECT id, name, created_at FROM matview_source
      SQL
    end

    # Create complex materialized view if not exists
    unless connection.select_value("SELECT COUNT(*) FROM pg_matviews WHERE matviewname = 'test_matview_complex'").to_i > 0
      connection.execute(<<~SQL)
        CREATE MATERIALIZED VIEW test_matview_complex AS
        SELECT id, name, value, active, metadata, created_at, updated_at
        FROM matview_source
      SQL
    end
  end
end
