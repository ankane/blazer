require_relative "test_helper"

class AnomalyChecksTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Check.delete_all
    Blazer::Query.delete_all
  end

  def test_prophet
    skip unless ENV["TEST_PROPHET"]

    assert_anomaly("prophet")
  end

  def test_trend
    skip unless ENV["TEST_TREND"]

    assert_anomaly("trend")
  end

  def test_anomaly_detection
    assert_anomaly("anomaly_detection")
  end

  def assert_anomaly(anomaly_checks)
    skip if !postgresql? || RUBY_ENGINE == "truffleruby"

    with_option(:anomaly_checks, anomaly_checks) do
      query = create_query(statement: "SELECT current_date + n AS day, 0.1 FROM generate_series(1, 30) n")
      check = create_check(query: query, check_type: "anomaly")

      Blazer.run_checks(schedule: "5 minutes")
      check.reload
      assert_equal "passing", check.state
      assert_equal "No anomalies detected", check.message

      query.update!(statement: "SELECT current_date + n AS day, 0.1 * random() AS v FROM generate_series(1, 30) n UNION ALL SELECT current_date + 31, 2 AS v")

      Blazer.run_checks(schedule: "5 minutes")
      check.reload
      assert_equal "failing", check.state
      assert_equal "Anomaly detected in v", check.message

      query.update!(statement: "SELECT 1")
      Blazer.run_checks(schedule: "5 minutes")
      check.reload
      assert_equal "error", check.state
      assert_equal "Bad format", check.message
    end
  end
end
