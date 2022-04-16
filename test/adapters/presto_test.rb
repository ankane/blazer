require_relative "../test_helper"

class PrestoTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "presto"
  end

  # TODO fix test_tables

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
