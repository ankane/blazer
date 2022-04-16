module AdapterTest
  # some adapter tests override this method
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
    assert_equal expected, run_statement(statement)
  end

  def run_statement(statement)
    run_query statement, data_source: data_source, format: "csv"
    CSV.parse(response.body, headers: true).map(&:to_h)
  end
end
