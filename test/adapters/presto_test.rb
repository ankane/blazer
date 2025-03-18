require_relative "../test_helper"

class PrestoTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "presto"
  end

  def test_tables
    # needs different connector
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end

  def test_audit
    assert_audit "SELECT 'world' AS hello", "SELECT {var} AS hello", var: "world"
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
end
