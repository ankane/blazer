require_relative "../test_helper"

class InfluxdbTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "influxdb"
  end

  def setup
    @@once ||= begin
      client = InfluxDB::Client.new(url: "http://localhost:8086/blazer_test")
      client.delete_series("items")
      client.write_point("items", {values: {value: 1}, tags: {hello: "world"}, timestamp: 0})
      client.write_point("items", {values: {value: 1}, tags: {hello: "'"}, timestamp: 0})
      client.write_point("items", {values: {value: 1}, tags: {hello: '"'}, timestamp: 0})
      # InfluxDB does not like trailing backslashes
      # https://github.com/influxdata/influxdb/issues/5231
      # https://github.com/influxdata/influxdb-ruby/issues/225
      client.write_point("items", {values: {value: 1}, tags: {hello: "\\a"}, timestamp: 0})
      true
    end
  end

  def test_run
    expected = [{"time" => "1970-01-01 00:00:00 UTC", "hello" => "world", "value" => "1"}]
    assert_result expected, "SELECT * FROM items WHERE hello = 'world'"
  end

  def test_audit
    assert_audit "SELECT * FROM items WHERE hello = 'world'", "SELECT * FROM items WHERE hello = {var}", var: "world"
  end

  def test_single_quote
    expected = [{"time" => "1970-01-01 00:00:00 UTC", "hello" => "'", "value" => "1"}]
    assert_result expected, "SELECT * FROM items WHERE hello = {var}", var: "'"
  end

  def test_double_quote
    expected = [{"time" => "1970-01-01 00:00:00 UTC", "hello" => '"', "value" => "1"}]
    assert_result expected, "SELECT * FROM items WHERE hello = {var}", var: '"'
  end

  def test_backslash
    expected = [{"time" => "1970-01-01 00:00:00 UTC", "hello" => "\\a", "value" => "1"}]
    assert_result expected, "SELECT * FROM items WHERE hello = {var}", var: "\\a"
  end
end
