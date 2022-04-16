require_relative "../test_helper"

class IgniteTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "ignite"
  end

  def test_run
    assert_result [{"HELLO" => "world"}], "SELECT 'world' AS hello"
  end
end
