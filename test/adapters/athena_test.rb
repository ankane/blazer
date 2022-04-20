require_relative "../test_helper"

class AthenaTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "athena"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end

  def test_audit
    if engine_version > 1
      assert_audit "SELECT ? AS hello\n\n[\"world\"]", "SELECT {var} AS hello", var: "world"
    else
      assert_audit "SELECT 'world' AS hello", "SELECT {var} AS hello", var: "world"
    end
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

  def test_bad_position
    if engine_version > 1
      assert_error "Exception parsing query", "SELECT 'world' AS {var}", var: "hello"
    else
      assert_error "mismatched input", "SELECT 'world' AS {var}", var: "hello"
    end
  end

  def test_quoted
    if engine_version > 1
      assert_error "Incorrect number of parameters: expected 0 but found 1", "SELECT '{var}' AS hello", var: "world"
    end
  end

  private

  def engine_version
    Blazer.data_sources[data_source].settings["engine_version"].to_i
  end
end
