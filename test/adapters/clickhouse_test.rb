require_relative "../test_helper"

class ClickhouseTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "clickhouse"
  end

  def setup
    super
    @@once ||= begin
      # TODO fix
      # ds.run_statement "CREATE TABLE users (id integer)"
      true
    end
  end

  def test_result
    result = ds.run_statement("SELECT 'world' AS hello")
    assert_equal [["world"]], result.rows
    assert_equal ["hello"], result.columns
    assert_equal ["string"], result.column_types
  end

  def test_error
    result = ds.run_statement("1")
    assert_match "Syntax error", result.error
  end

  def test_timeout
    result = ds.run_statement("SELECT sleep(1)")
    assert_equal "Query timed out :(", result.error
  end

  def test_tables_method
    tables = ds.tables
    assert_includes tables, "users"
  end

  def test_schema_method
    schema = ds.schema
    columns = schema.to_h { |v| [v[:table], v[:columns]] }
    expected = [
      {name: "id", data_type: "Int32"}
    ]
    assert_equal expected, columns["users"]
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end

  def test_audit
    assert_audit "SELECT {var: String} AS hello\n\n{\"var\":\"world\"}", "SELECT {var} AS hello", var: "world"
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
    assert_result [{"hello" => "2022-01-01 08:00:00 UTC"}], "SELECT {created_at} AS hello", created_at: "2022-01-01 08:00:00"
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

  # TODO fix
  # def test_backslash
  #   assert_result [{"hello" => "\\"}], "SELECT {var} AS hello", var: "\\"
  # end
end
