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

  def test_error
    query = create_query(statement: "invalid")
    check = create_check(query: query, check_type: "bad_data")
    Blazer.run_checks(schedule: "5 minutes")
    check.reload
    assert_equal "error", check.state
  end

  def test_emails
    query = create_query
    check = create_check(query: query, check_type: "bad_data", emails: "hi@example.org,hi2@example.org")

    assert_emails 0 do
      Blazer.send_failing_checks
    end

    assert_emails 1 do
      Blazer.run_checks(schedule: "5 minutes")
    end

    assert_emails 2 do
      Blazer.send_failing_checks
    end
  end

  def test_slack
    query = create_query
    check = create_check(query: query, check_type: "bad_data", slack_channels: "#general,#random")

    assert_slack_messages 0 do
      Blazer.send_failing_checks
    end

    assert_slack_messages 2 do
      Blazer.run_checks(schedule: "5 minutes")
    end

    assert_slack_messages 2 do
      Blazer.send_failing_checks
    end
  end

  def assert_slack_messages(expected)
    count = 0
    Blazer::SlackNotifier.stub :post_api, ->(*) { count += 1 } do
      yield
    end
    assert_equal expected, count
  end
end
