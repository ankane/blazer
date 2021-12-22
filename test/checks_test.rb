require_relative "test_helper"

class ChecksTest < ActionDispatch::IntegrationTest
  def test_index
    get blazer.checks_path
    assert_response :success
  end
end
