require_relative "../test_helper"

class CassandraTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "cassandra"
  end

  def setup
    @@once ||= begin
      require "cassandra"
      cluster = Cassandra.cluster(hosts: ["localhost"])

      session = cluster.connect("system")
      session.execute("CREATE KEYSPACE IF NOT EXISTS blazer_test WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 }")

      session = cluster.connect("blazer_test")
      session.execute("DROP TABLE IF EXISTS items")
      session.execute("CREATE TABLE items (id int, name text, PRIMARY KEY (id))")
      true
    end
  end

  def test_run
    assert_result [{"count" => "0"}], "SELECT COUNT(*) FROM items"
  end
end
