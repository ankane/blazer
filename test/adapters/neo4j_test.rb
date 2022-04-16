require_relative "../test_helper"

class Neo4jTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "neo4j"
  end

  def test_run
    assert_result [{"hello" => "world"}], "OPTIONAL MATCH () RETURN 'world' AS `hello`"
  end
end
