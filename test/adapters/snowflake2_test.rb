require_relative "../test_helper"

class Snowflake2Test < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "snowflake2"
  end

  def test_result
    result = ds.run_statement("SELECT 'world' AS hello")
    assert_equal [["world"]], result.rows
    assert_equal ["HELLO"], result.columns
    assert_equal ["string"], result.column_types
  end

  def test_error
    result = ds.run_statement("1")
    assert_match "syntax error", result.error
  end

  def test_timeout
    result = ds.run_statement("SELECT SYSTEM$WAIT(3)")
    assert_equal "Query timed out :(", result.error
  end

  def test_run
    assert_result [{"HELLO" => "world"}], "SELECT 'world' AS hello"
  end

  def test_audit
    assert_audit "SELECT ? AS hello\n\n[\"world\"]", "SELECT {var} AS hello", var: "world"
  end

  def test_string
    assert_result [{"HELLO" => "world"}], "SELECT {var} AS hello", var: "world"
  end

  def test_integer
    assert_result [{"HELLO" => "1"}], "SELECT {var} AS hello", var: "1"
  end

  def test_float
    assert_result [{"HELLO" => "1.5"}], "SELECT {var} AS hello", var: "1.5"
  end

  def test_time
    assert_result [{"HELLO" => "2022-01-01 08:00:00 UTC"}], "SELECT {created_at} AS hello", created_at: "2022-01-01 08:00:00"
  end

  def test_nil
    assert_result [{"HELLO" => nil}], "SELECT {var} AS hello", var: ""
  end

  def test_single_quote
    assert_result [{"HELLO" => "'"}], "SELECT {var} AS hello", var: "'"
  end

  def test_double_quote
    assert_result [{"HELLO" => '"'}], "SELECT {var} AS hello", var: '"'
  end

  def test_backslash
    assert_result [{"HELLO" => "\\"}], "SELECT {var} AS hello", var: "\\"
  end

  def test_double_backslash
    assert_result [{"HELLO" => "\\\\"}], "SELECT {var} AS hello", var: "\\\\"
  end
end
