require_relative "test_helper"

class UploadsTest < ActionDispatch::IntegrationTest
  def setup
    skip unless postgresql?
    super
    Blazer::Upload.delete_all
    Blazer::UploadsConnection.connection.execute("DROP SCHEMA IF EXISTS uploads CASCADE")
    Blazer::UploadsConnection.connection.execute("CREATE SCHEMA uploads")
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
    create_upload
    upload = Blazer::Upload.last
    assert_redirected_to blazer.upload_path(upload)

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

  def test_create_duplicate_table
    create_upload
    upload = Blazer::Upload.last
    assert_redirected_to blazer.upload_path(upload)
    Blazer::Upload.delete_all

    create_upload
    assert_response :unprocessable_entity
    assert_match "Table already exists", response.body
  end

  def test_show
    create_upload
    upload = Blazer::Upload.last

    get blazer.upload_path(upload)
    assert_redirected_to blazer.new_query_path(upload_id: upload.id)
  end

  def test_edit
    create_upload
    upload = Blazer::Upload.last

    get blazer.edit_upload_path(upload)
    assert_response :success
  end

  def test_update_rename
    create_upload
    upload = Blazer::Upload.last
    assert_redirected_to blazer.upload_path(upload)

    patch blazer.upload_path(upload), params: {upload: {table: "items"}}
    assert_redirected_to blazer.upload_path(upload)

    tables = Blazer::UploadsConnection.connection.select_all("SELECT table_name FROM information_schema.tables WHERE table_schema = 'uploads'").rows.map(&:first)
    assert_equal ["items"], tables
  end

  def test_destroy
    create_upload
    upload = Blazer::Upload.last

    delete blazer.upload_path(upload)
    assert_redirected_to blazer.uploads_path

    assert_raises(ActiveRecord::RecordNotFound) do
      upload.reload
    end
  end

  def test_bad_content_type
    create_upload(content_type: "text/plain")
    assert_response :unprocessable_entity
    assert_match "File is not a CSV", response.body
  end

  def test_malformed_csv
    create_upload(file: "malformed.csv")
    assert_response :unprocessable_entity
    assert_match "Unclosed quoted field in line 1", response.body
  end

  def test_duplicate_columns
    create_upload(file: "duplicate_columns.csv")
    assert_response :unprocessable_entity
    assert_match "Duplicate column name: a", response.body
  end

  private

  def create_upload(file: "line_items.csv", content_type: "text/csv")
    post blazer.uploads_path, params: {upload: {table: "line_items", description: "Billing line items", file: fixture_file_upload("test/support/#{file}", content_type)}}
  end
end
