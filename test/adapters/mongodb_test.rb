require_relative "../test_helper"

class MongodbTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "mongodb"
  end

  def setup
    @@once ||= begin
      client = Mongo::Client.new(["127.0.0.1:27017"], database: "blazer_test")
      client[:items].drop
      client[:items].insert_one({hello: "world"})
      true
    end
  end

  def test_run
    assert_result [{"hello" => "world"}], "db.items.find({}, {hello: 1, _id: 0})"
  end
end
