require_relative "../test_helper"

class SodaTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "soda"
  end

  def test_tables
    assert_equal ["all"], tables
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello LIMIT 1"
  end
end
