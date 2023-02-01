require_relative "test_helper"

class PermissionsTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Query.delete_all
    User.delete_all
  end

  def test_list
    with_new_user do |user|
      create_query(name: "# Test", creator: user)
      get blazer.root_path
      assert_response :success
      assert_match "# Test", response.body
    end

    with_new_user do
      get blazer.root_path
      assert_response :success
      refute_match "# Test", response.body
    end
  end

  private

  def with_new_user
    user = User.create!
    yield user
  end
end
