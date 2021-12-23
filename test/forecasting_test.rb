require_relative "test_helper"

class ForecastingTest < ActionDispatch::IntegrationTest
  def test_prophet
    skip unless ENV["TEST_PROPHET"]

    assert_forecast("prophet")
  end

  def test_trend
    skip unless ENV["TEST_TREND"]

    assert_forecast("trend")
  end

  def assert_forecast(forecasting)
    previous_value = Blazer.forecasting
    begin
      Blazer.forecasting = forecasting

      query = create_query(statement: "SELECT current_date + n AS day, n FROM generate_series(1, 30) n")
      run_query query.statement, query_id: query.id, forecast: "t"
      assert_match %{"name":"forecast"}, response.body
    ensure
      Blazer.forecasting = previous_value
    end
  end
end
