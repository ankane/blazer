require_relative "../test_helper"

class OpensearchTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "opensearch"
  end

  def test_run
    assert_result [{"'world'" => "world"}], "SELECT 'world' AS hello"
  end

  def test_single_quote
    assert_error "Quoting not specified", "SELECT {var} AS hello", var: "'"
  end

  def test_double_quote
    assert_error "Quoting not specified", "SELECT {var} AS hello", var: '"'
  end

  def test_backslash
    assert_error "Quoting not specified", "SELECT {var} AS hello", var: "\\"
  end
end
