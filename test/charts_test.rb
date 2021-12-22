require_relative "test_helper"

class ChartsTest < ActionDispatch::IntegrationTest
  def test_line_chart
    run_query "SELECT NOW(), 1"
    assert_match "LineChart", response.body
  end

  def test_column_chart_format1
    run_query "SELECT 'Label', 1"
    assert_match "ColumnChart", response.body
  end

  def test_column_chart_format2
    run_query "SELECT 'Label', 'Group', 1"
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

  def test_cohort_analysis
    run_query "SELECT 1 AS user_id, NOW() AS conversion_time /* cohort analysis */", query_id: 1
    assert_match "1 cohort", response.body
  end

  def test_forecasting
    skip "Too slow" unless ENV["TEST_FORECASTING"]

    query = Blazer::Query.create!(statement: "SELECT current_date + n AS day, n FROM generate_series(1, 30) n", data_source: "main")
    run_query query.statement, query_id: query.id, forecast: "t"
    assert_match %{"name":"forecast"}, response.body
  end
end
