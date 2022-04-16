require_relative "../test_helper"

# CREATE KEYSPACE blazer_test WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };
# USE blazer_test;
# CREATE TABLE items (id int, name text, PRIMARY KEY (id));

class CassandraTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "cassandra"
  end

  def test_run
    assert_result [{"count" => "0"}], "SELECT COUNT(*) FROM items"
  end
end
