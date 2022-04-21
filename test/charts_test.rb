require_relative "test_helper"

class ChartsTest < ActionDispatch::IntegrationTest
  def test_line_chart_format1
    run_query "SELECT NOW(), 1"
    assert_match "LineChart", response.body
  end

  def test_line_chart_format2
    run_query "SELECT NOW(), 'Label', 1"
    assert_match "LineChart", response.body
  end

  def test_column_chart_format1
    run_query "SELECT 'Label' AS label, 1"
    assert_match "ColumnChart", response.body
  end

  def test_column_chart_format2
    run_query "SELECT 'Label' AS label, 'Group' AS group, 1"
    assert_match "ColumnChart", response.body
    assert_match %{"name":"Group"}, response.body
  end

  def test_scatter_chart
    run_query "SELECT 1, 2"
    assert_match "ScatterChart", response.body
  end

  def test_pie_chart
    run_query "SELECT 'Label', 1 AS pie"
    assert_match "PieChart", response.body
  end

  def test_map_latitude_longitude
    run_query "SELECT 1.2 AS latitude, 3.4 AS longitude"
    assert_match "map", response.body
  end

  def test_map_lat_lon
    run_query "SELECT 1.2 AS lat, 3.4 AS lon"
    assert_match "map", response.body
  end

  def test_map_lat_lng
    run_query "SELECT 1.2 AS lat, 3.4 AS lng"
    assert_match "map", response.body
  end

  def test_target
    run_query "SELECT NOW(), 1, 2 AS target"
    assert_match %{"name":"target"}, response.body
  end
end
