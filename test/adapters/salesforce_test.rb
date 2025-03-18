require_relative "../test_helper"

# https://stackoverflow.com/questions/12794302/salesforce-authentication-failing/29112224#29112224
# create accounts named world, ', ", and \

# ENV["SALESFORCE_USERNAME"] = "username"
# ENV["SALESFORCE_PASSWORD"] = "password"
# ENV["SALESFORCE_SECURITY_TOKEN"] = "security token"
# ENV["SALESFORCE_CLIENT_ID"] = "client id"
# ENV["SALESFORCE_CLIENT_SECRET"] = "client secret"
# ENV["SALESFORCE_API_VERSION"] = "41.0"

class SalesforceTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "salesforce"
  end

  def test_run
    assert_result [{"Name" => "world"}], "SELECT Name FROM Account WHERE Name = 'world'"
  end

  def test_single_quote
    assert_result [{"Name" => "'"}], "SELECT Name FROM Account WHERE Name = {var}", var: "'"
  end

  def test_double_quote
    assert_result [{"Name" => '"'}], "SELECT Name FROM Account WHERE Name = {var}", var: '"'
  end

  def test_backslash
    assert_result [{"Name" => "\\"}], "SELECT Name FROM Account WHERE Name = {var}", var: "\\"
  end
end
