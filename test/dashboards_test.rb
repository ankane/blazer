require_relative "test_helper"

class DashboardsTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Query.delete_all
    Blazer::Dashboard.delete_all
  end

  def test_new
    get blazer.new_dashboard_path
    assert_response :success
  end

  def test_create
    post blazer.dashboards_path(params: {dashboard: {name: "Test"}})
    dashboard = Blazer::Dashboard.last
    assert_redirected_to blazer.dashboard_path(dashboard)
    assert_equal "Test", dashboard.name
  end

  def test_show
    dashboard = create_dashboard
    get blazer.dashboard_path(dashboard)
    assert_response :success
  end

  def test_edit
    dashboard = create_dashboard
    get blazer.edit_dashboard_path(dashboard)
    assert_response :success
  end

  def test_update
    dashboard = create_dashboard
    patch blazer.dashboard_path(dashboard, params: {dashboard: {name: "Updated"}})
    dashboard.reload
    assert_redirected_to blazer.dashboard_path(dashboard)
    assert_equal "Updated", dashboard.name
  end

  def test_destroy
    dashboard = create_dashboard
    delete blazer.dashboard_path(dashboard)
    assert_redirected_to blazer.root_path

    assert_raises(ActiveRecord::RecordNotFound) do
      dashboard.reload
    end
  end

  def test_refresh
    dashboard = create_dashboard
    dashboard.queries << create_query
    post blazer.refresh_dashboard_path(dashboard)
    assert_redirected_to blazer.dashboard_path(dashboard)
  end

  def create_dashboard
    Blazer::Dashboard.create!(name: "Test")
  end
end
