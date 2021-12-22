require_relative "test_helper"

class UploadsTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Upload.delete_all
  end

  # TODO test column types
  def test_create
    post blazer.uploads_path, params: {upload: {table: "line_items", description: "Billing line items", file: fixture_file_upload("test/support/line_items.csv", "text/csv")}}
    assert_response :redirect

    upload = Blazer::Upload.last
    assert_equal "line_items", upload.table
    assert_equal "Billing line items", upload.description

    run_query "SELECT * FROM uploads.line_items"
    assert_response :success
  end
end
