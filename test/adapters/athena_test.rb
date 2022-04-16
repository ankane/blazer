require_relative "../test_helper"

class AthenaTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "athena"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
