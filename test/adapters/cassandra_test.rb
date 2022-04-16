require_relative "../test_helper"

# CREATE KEYSPACE blazer_test
# WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };

class CassandraTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "cassandra"
  end
end
