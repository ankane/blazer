require_relative "../test_helper"

class MysqlTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "mysql"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end

  def test_audit
    if prepared_statements?
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

  def test_multiple_variables
    assert_result [{"c1" => "one", "c2" => "two", "c3" => "one"}], "SELECT {var} AS c1, {var2} AS c2, {var} AS c3", var: "one", var2: "two"
  end

  def test_bad_position
    if prepared_statements?
      assert_bad_position "SELECT 'world' AS {var}", var: "hello"
    else
      assert_result [{"hello"=>"world"}], "SELECT 'world' AS {var}", var: "hello"
    end
  end

  def test_bad_position_before
    if prepared_statements?
      assert_result [{"?" => "world"}], "SELECT{var}", var: "world"
    else
      assert_result [{"world" => "world"}], "SELECT{var}", var: "world"
    end
  end

  def test_bad_position_after
    if prepared_statements?
      assert_bad_position "SELECT {var}456", var: "world"
    else
      assert_error "You have an error in your SQL syntax", "SELECT {var}456", var: "world"
    end
  end

  def test_quoted
    if prepared_statements?
      assert_error "Bind parameter count (0) doesn't match number of arguments (1)", "SELECT '{var}' AS hello", var: "world"
    else
      assert_error "You have an error in your SQL syntax", "SELECT '{var}' AS hello", var: "world"
    end
  end

  def test_binary
    # checks for successful response
    run_statement "SELECT UNHEX('F6'), 1", format: "html"
  end

  private

  def prepared_statements?
    Blazer.data_sources[data_source].settings["url"].include?("prepared_statements=true")
  end
end
