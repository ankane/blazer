require_relative "../test_helper"

class SqliteTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "sqlite"
  end

  def setup
    super
    @@once ||= begin
      execute "CREATE TABLE users (id integer)"
      execute "CREATE VIEW users_view AS SELECT * FROM users"
      true
    end
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


  def test_tables_method
    tables = ds.tables
    assert_includes tables, "users"
    assert_includes tables, "users_view"
  end

  def test_schema_method
    schema = ds.schema
    tables = schema.map { |v| v[:table] }
    assert_includes tables, "users"
    assert_includes tables, "users_view"
  end
end
