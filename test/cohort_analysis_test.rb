require_relative "test_helper"

class CohortAnalysisTest < ActionDispatch::IntegrationTest
  def test_works
    run_query "SELECT 1 AS user_id, NOW() AS conversion_time /* cohort analysis */", query_id: 1
    assert_match "1 cohort", response.body
  end

  def test_cohort_time
    run_query "SELECT 1 AS user_id, NOW() AS cohort_time, NOW() AS conversion_time /* cohort analysis */", query_id: 1
    assert_match "1 cohort", response.body
  end

  def test_cohort_period_default
    query = create_query(statement: "SELECT 1 AS user_id, NOW() AS conversion_time /* cohort analysis */")
    get blazer.query_path(query)
    assert_response :success
    assert_match %{selected="selected" value="week"}, response.body
  end

  def test_missing_columns
    run_query "SELECT 1 /* cohort analysis */", query_id: 1
    assert_match "alert-danger", response.body
  end
end
