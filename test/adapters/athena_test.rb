require_relative "../test_helper"

class AthenaTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "athena"
  end
end
