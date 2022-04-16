require_relative "../test_helper"

# bin/beeline -u jdbc:hive2://localhost:10000 -e 'CREATE DATABASE blazer_test;'

class SparkTest < ActionDispatch::IntegrationTest
  include AdapterTest

  def data_source
    "spark"
  end

  def test_run
    assert_result [{"hello" => "world"}], "SELECT 'world' AS hello"
  end
end
