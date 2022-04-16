require_relative "../test_helper"

# brew install freetds
# docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=YourStrong!Passw0rd' -p 1433:1433 -d mcr.microsoft.com/mssql/server:2019-latest
# docker exec -it <container-id> /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P YourStrong\!Passw0rd -Q "CREATE DATABASE blazer_test"

class SqlserverTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "sqlserver"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
