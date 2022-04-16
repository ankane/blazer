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
end
