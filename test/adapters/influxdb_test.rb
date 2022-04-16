require_relative "../test_helper"

# USE blazer_test
# DROP SERIES FROM items
# INSERT items,hello=world value=1

class InfluxdbTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "influxdb"
  end

  def test_run
    expected = [{"time" => "1970-01-01 00:00:00 UTC", "count_value" => "1"}]
    assert_result expected, "SELECT COUNT(*) FROM items WHERE hello = 'world'"
  end
end
