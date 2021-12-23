require_relative "test_helper"

class CohortAnalysisTest < ActionDispatch::IntegrationTest
  def test_postgres
    run_query "SELECT 1 AS user_id, NOW() AS conversion_time /* cohort analysis */", query_id: 1
    assert_match "1 cohort", response.body
  end

  def test_mysql
    skip unless ENV["TEST_MYSQL"]

    run_query "SELECT 1 AS user_id, NOW() AS conversion_time /* cohort analysis */", query_id: 1, data_source: "mysql"
    assert_match "1 cohort", response.body
  end
end
