require_relative "test_helper"

class UploadsTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Upload.delete_all
  end

  def test_index
    get blazer.uploads_path
    assert_response :success
  end

  def test_new
    get blazer.new_upload_path
    assert_response :success
  end

  def test_create
    post blazer.uploads_path, params: {upload: {table: "line_items", description: "Billing line items", file: fixture_file_upload("test/support/line_items.csv", "text/csv")}}
    assert_response :redirect

    upload = Blazer::Upload.last
    assert_equal "line_items", upload.table
    assert_equal "Billing line items", upload.description

    run_query "SELECT * FROM uploads.line_items"
    assert_response :success

    column_types = Blazer::UploadsConnection.connection.select_all("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = 'uploads' AND table_name = 'line_items'").rows.to_h
    assert_equal "bigint", column_types["a"]
    assert_equal "numeric", column_types["b"]
    assert_equal "timestamp with time zone", column_types["c"]
    assert_equal "date", column_types["d"]
    assert_equal "text", column_types["e"]
    assert_equal "text", column_types["f"]
  end
end
