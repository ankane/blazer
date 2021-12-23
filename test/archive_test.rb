require_relative "test_helper"

class ArchiveTest < ActionDispatch::IntegrationTest
  def setup
    Blazer::Audit.delete_all
    Blazer::Query.delete_all
  end

  def test_archive_queries
    query = create_query
    query2 = create_query
    query2.audits.create!

    Blazer.archive_queries

    query.reload
    assert_equal "archived", query.status
    query2.reload
    assert_equal "active", query2.status
  end
end
