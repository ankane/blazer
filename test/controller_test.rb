require_relative "test_helper"

class ControllerTest < ActionDispatch::IntegrationTest
  def test_index
    get blazer.root_path
    assert_response :success
  end
end
