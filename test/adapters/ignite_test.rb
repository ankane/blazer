require_relative "../test_helper"

class IgniteTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "ignite"
  end
end
