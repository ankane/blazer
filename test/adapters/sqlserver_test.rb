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

  def test_audit
    assert_audit "SELECT @0  AS hello\n\n[\"world\"]", "SELECT {var} AS hello", var: "world"
  end

  def test_string
    assert_result [{"hello" => "world"}], "SELECT {var} AS hello", var: "world"
  end

  def test_integer
    assert_result [{"hello" => "1"}], "SELECT {var} AS hello", var: "1"
  end

  # https://github.com/rails-sqlserver/activerecord-sqlserver-adapter/issues/643
  # should be 1.5
  def test_float
    assert_result [{"hello" => "1"}], "SELECT {var} AS hello", var: "1.5"
  end

  def test_time
    assert_result [{"hello" => "01-01-2022 08:00:00.0"}], "SELECT {created_at} AS hello", created_at: "2022-01-01 08:00:00"
  end

  def test_nil
    assert_result [{"hello" => nil}], "SELECT {var} AS hello", var: ""
  end

  def test_single_quote
    assert_result [{"hello" => "'"}], "SELECT {var} AS hello", var: "'"
  end

  def test_double_quote
    assert_result [{"hello" => '"'}], "SELECT {var} AS hello", var: '"'
  end

  def test_backslash
    assert_result [{"hello" => "\\"}], "SELECT {var} AS hello", var: "\\"
  end

  def test_bad_position
    assert_bad_position "SELECT 'world' AS {var}", var: "hello"
  end

  def test_quoted
    assert_result [{"hello"=>"@0 "}], "SELECT '{var}' AS hello", var: "world"
  end
end
