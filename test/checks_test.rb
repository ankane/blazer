require_relative "test_helper"

class ChecksTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Check.delete_all
    Blazer::Query.delete_all
  end

  def test_index
    get blazer.checks_path
    assert_response :success
  end

  def test_bad_data
    query = create_query
    check = create_check(query: query, check_type: "bad_data")

    Blazer.run_checks(schedule: "5 minutes")
    check.reload
    assert_equal "failing", check.state

    query.update!(statement: "SELECT 1 LIMIT 0")

    Blazer.run_checks(schedule: "5 minutes")
    check.reload
    assert_equal "passing", check.state
  end

  def test_missing_data
    query = create_query
    check = create_check(query: query, check_type: "missing_data")

    Blazer.run_checks(schedule: "5 minutes")
    check.reload
    assert_equal "passing", check.state

    query.update!(statement: "SELECT 1 LIMIT 0")

    Blazer.run_checks(schedule: "5 minutes")
    check.reload
    assert_equal "failing", check.state
  end

  def test_emails
    query = create_query
    check = create_check(query: query, check_type: "bad_data", emails: "hi@example.org")

    assert_emails 0 do
      Blazer.send_failing_checks
    end

    assert_emails 1 do
      Blazer.run_checks(schedule: "5 minutes")
    end

    assert_emails 1 do
      Blazer.send_failing_checks
    end
  end

  def create_check(**attributes)
    Blazer::Check.create!(schedule: "5 minutes", **attributes)
  end
end
