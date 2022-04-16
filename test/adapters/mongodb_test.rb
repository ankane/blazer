require_relative "../test_helper"

class MongodbTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "mongodb"
  end

  def test_run
    assert_result [], "db.items.find()"
  end
end
