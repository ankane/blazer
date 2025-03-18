require_relative "../test_helper"

class IgniteTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "ignite"
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

  def test_bad_position
    assert_error "Syntax error in SQL statement", "SELECT 'world' AS {var}", var: "hello"
  end
end
