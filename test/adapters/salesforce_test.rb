require_relative "../test_helper"

class SalesforceTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "salesforce"
  end
end
