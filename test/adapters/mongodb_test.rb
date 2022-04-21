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
      client[:items].insert_one({hello: "'"})
      client[:items].insert_one({hello: '"'})
      client[:items].insert_one({hello: "\\"})
      true
    end
  end

  def test_run
    assert_result [{"hello" => "world"}], "db.items.find({hello: 'world'}, {hello: 1, _id: 0})"
  end

  def test_audit
    assert_audit "db.items.find({hello: 'world'}, {hello: 1, _id: 0})", "db.items.find({hello: {var}}, {hello: 1, _id: 0})", var: "world"
  end

  def test_single_quote
    assert_result [{"hello" => "'"}], "db.items.find({hello: {var}}, {hello: 1, _id: 0})", var: "'"
  end

  def test_double_quote
    assert_result [{"hello" => '"'}], "db.items.find({hello: {var}}, {hello: 1, _id: 0})", var: '"'
  end

  def test_backslash
    assert_result [{"hello" => "\\"}], "db.items.find({hello: {var}}, {hello: 1, _id: 0})", var: "\\"
  end
end
