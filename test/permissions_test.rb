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

  def test_edit
    query =
      with_new_user do |user|
        create_query(name: "* Test", creator: user)
      end

    with_new_user do
      patch blazer.query_path(query), params: {query: {name: "Renamed"}}
      assert_response :unprocessable_entity
      assert_match "Sorry, permission denied", response.body

      delete blazer.query_path(query)
      # TODO error response
      assert_response :redirect
      assert Blazer::Query.exists?(query.id)
    end
  end

  def test_change_creator
    with_new_user do |user|
      query = create_query(name: "Test", creator: user)

      patch blazer.query_path(query), params: {query: {name: "* Test"}}
      assert_response :redirect

      patch blazer.query_path(query), params: {query: {name: "# Test"}}
      assert_response :redirect
    end
  end

  private

  def with_new_user
    user = User.create!
    yield user
  end
end
