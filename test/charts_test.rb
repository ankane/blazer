require_relative "test_helper"

class ChartsTest < ActionDispatch::IntegrationTest
  # TODO fix casting
  def test_line_chart
    run_query "SELECT date('now'), 1"
    # assert_match "LineChart", response.body
  end

  def test_column_chart
    run_query "SELECT 'Label', 1"
    assert_match "ColumnChart", response.body
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

  # TODO update
  def test_target
    run_query "SELECT date('now'), 1, 2 AS target"
  end

  def run_query(statement)
    post blazer.run_queries_path, params: {statement: statement, data_source: "main"}, xhr: true
    assert_response :success
  end
end
