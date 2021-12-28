require_relative "test_helper"

class AnomalyChecksTest < ActionDispatch::IntegrationTest
  def test_prophet
    skip unless ENV["TEST_PROPHET"]

    assert_anomaly("prophet")
  end

  def test_trend
    skip unless ENV["TEST_TREND"]

    assert_anomaly("trend")
  end

  def test_anomaly_detection
    skip unless ENV["TEST_ANOMALY_DETECTION"]

    assert_anomaly("anomaly_detection")
  end

  def assert_anomaly(anomaly_checks)
    Blazer.stub(:anomaly_checks, anomaly_checks) do
      query = create_query(statement: "SELECT current_date + n AS day, 0.1 * random() FROM generate_series(1, 30) n")
      check = create_check(query: query, check_type: "anomaly")

      Blazer.run_checks(schedule: "5 minutes")
      check.reload
      assert_equal "passing", check.state

      query.update!(statement: "SELECT current_date + n AS day, 0.1 * random() FROM generate_series(1, 30) n UNION ALL SELECT current_date + 31, 2")

      Blazer.run_checks(schedule: "5 minutes")
      check.reload
      assert_equal "failing", check.state
    end
  end
end
