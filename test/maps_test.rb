require_relative "test_helper"

class MapsTest < ActionDispatch::IntegrationTest
  def test_latitude_longitude
    run_query "SELECT 1.2 AS latitude, 3.4 AS longitude"
    assert_match "Map", response.body
  end

  def test_lat_lon
    run_query "SELECT 1.2 AS lat, 3.4 AS lon"
    assert_match "Map", response.body
  end

  def test_lat_lng
    run_query "SELECT 1.2 AS lat, 3.4 AS lng"
    assert_match "Map", response.body
  end

  def test_geojson
    run_query "SELECT '{}' AS geojson"
    assert_match "AreaMap", response.body
  end
end
