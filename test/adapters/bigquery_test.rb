require_relative "../test_helper"

class BigqueryTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "bigquery"
  end
end
