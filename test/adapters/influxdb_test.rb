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
      true
    end
  end

  def test_run
    expected = [{"time" => "1970-01-01 00:00:00 UTC", "count_value" => "1"}]
    assert_result expected, "SELECT COUNT(*) FROM items WHERE hello = 'world'"
  end
end
