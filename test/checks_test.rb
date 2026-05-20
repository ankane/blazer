require_relative "test_helper"

class ChecksTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Check.delete_all
    Blazer::Query.delete_all
  end

  def test_index
    query = create_query
    create_check(query: query, check_type: "bad_data", emails: "hi@example.org")

    get blazer.checks_path
    assert_response :success
    assert_match "hi@example.org", response.body
  end

  def test_index_q
    query = create_query
    create_check(query: query, check_type: "bad_data", emails: "hi@example.org")
    create_check(query: query, check_type: "bad_data", emails: "hello@example.org")

    get blazer.checks_path(q: "hi")
    assert_response :success
    assert_match "hi@example.org", response.body
    refute_match "hello@example.org", response.body
  end

  def test_new
    get blazer.new_check_path
    assert_response :success
  end

  def test_create
    query = create_query

    post blazer.checks_path(params: {check: {query_id: query.id, schedule: "5 minutes", check_type: "bad_data", emails: "hi@example.org"}})
    assert_response :redirect
  end

  def test_update
    query = create_query
    check = create_check(query: query, check_type: "bad_data")

    patch blazer.check_path(check, params: {check: {schedule: "1 hour"}})
    assert_response :redirect

    check.reload
    assert_equal "1 hour", check.schedule
  end

  def test_destroy
    query = create_query
    check = create_check(query: query, check_type: "bad_data")

    delete blazer.check_path(check)
    assert_response :redirect

    assert_raises(ActiveRecord::RecordNotFound) do
      check.reload
    end
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
    create_check(query: query, check_type: "bad_data", emails: "hi@example.org,hi2@example.org")

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

  def test_emails_normalize
    query = create_query
    check = create_check(query: query, check_type: "bad_data", emails: "hi@example.org;hi2@example.org")
    assert_equal "hi@example.org, hi2@example.org", check.emails

    check.update!(emails: "hi@example.org,   hi2@example.org")
    assert_equal "hi@example.org, hi2@example.org", check.emails
  end

  def test_emails_invalid
    query = create_query

    post blazer.checks_path(params: {check: {query_id: query.id, schedule: "5 minutes", check_type: "bad_data", emails: "hi"}})
    assert_response :unprocessable_entity
    assert_match "Invalid emails", response.body
  end

  def test_slack
    query = create_query
    create_check(query: query, check_type: "bad_data", slack_channels: "#general,#random")

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
    stub_method(Blazer::SlackNotifier, :post_api, ->(*) { count += 1 }) do
      yield
    end
    assert_equal expected, count
  end
end
