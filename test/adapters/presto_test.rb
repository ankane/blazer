require_relative "../test_helper"

class PrestoTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "presto"
  end
end
