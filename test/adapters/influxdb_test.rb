require_relative "../test_helper"

class InfluxdbTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "influxdb"
  end
end
