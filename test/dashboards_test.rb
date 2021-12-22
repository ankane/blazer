require_relative "test_helper"

class DashboardsTest < ActionDispatch::IntegrationTest
  def test_new
    get blazer.new_dashboard_path
    assert_response :success
  end
end
