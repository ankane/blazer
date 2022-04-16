require_relative "../test_helper"

class RedshiftTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "redshift"
  end
end
