require_relative "../test_helper"

class SodaTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "soda"
  end
end
