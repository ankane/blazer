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
      session.execute("CREATE TABLE items (id int, hello text, PRIMARY KEY (id))")
      session.execute("INSERT INTO items (id, hello) VALUES (1, 'world')")
      session.execute("INSERT INTO items (id, hello) VALUES (2, '''')")
      session.execute("INSERT INTO items (id, hello) VALUES (3, '\"')")
      session.execute("INSERT INTO items (id, hello) VALUES (4, '\\')")
      true
    end
  end

  def test_tables
    assert_equal ["items"], tables
  end

  def test_run
    expected = [{"hello" => 'world'}]
    assert_result expected, "SELECT hello FROM items WHERE hello = 'world' ALLOW FILTERING"
  end

  def test_audit
    expected = "SELECT hello FROM items WHERE hello = ? ALLOW FILTERING\n\n[\"world\"]"
    assert_audit expected, "SELECT hello FROM items WHERE hello = {var} ALLOW FILTERING", var: "world"
  end

  def test_single_quote
    expected = [{"hello" => "'"}]
    assert_result expected, "SELECT hello FROM items WHERE hello = {var} ALLOW FILTERING", var: "'"
  end

  def test_double_quote
    expected = [{"hello" => '"'}]
    assert_result expected, "SELECT hello FROM items WHERE hello = {var} ALLOW FILTERING", var: '"'
  end

  def test_backslash
    expected = [{"hello" => "\\"}]
    assert_result expected, "SELECT hello FROM items WHERE hello = {var} ALLOW FILTERING", var: "\\"
  end

  def test_bad_position
    assert_bad_position "SELECT hello FROM items WHERE hello {var} 'world' ALLOW FILTERING", var: "="
  end
end
