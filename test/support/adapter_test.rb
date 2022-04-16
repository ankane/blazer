module AdapterTest
  def test_tables
    assert_kind_of Array, tables
  end

  private

  def tables
    get blazer.tables_queries_path(data_source: data_source)
    assert_response :success
    JSON.parse(response.body)
  end

  def assert_result(expected, statement)
    run_query statement, data_source: data_source, format: "csv"
    assert_response :success
    assert_equal expected, CSV.parse(response.body, headers: true).map(&:to_h)
  end
end
