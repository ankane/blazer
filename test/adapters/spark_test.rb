require_relative "../test_helper"

class SparkTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "spark"
  end
end
