require_relative "../test_helper"

class HiveTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "hive"
  end
end
