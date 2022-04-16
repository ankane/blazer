require_relative "../test_helper"

class Neo4jTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "neo4j"
  end
end
