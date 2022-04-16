require_relative "../test_helper"

class MongodbTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "mongodb"
  end
end
