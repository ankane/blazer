require_relative "../test_helper"

class OpensearchTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "opensearch"
  end

  def test_run
    assert_result [{"'world'" => "world"}], "SELECT 'world' AS hello"
  end
end
