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

  def assert_result(expected, statement, **params)
    assert_equal expected, run_statement(statement, **params)
  end

  def assert_audit(expected, statement, **params)
    run_statement(statement, **params)
    assert_equal expected, Blazer::Audit.last.statement
  end

  def assert_error(message, statement, **params)
    error = assert_raises(Blazer::Error) do
      run_statement(statement, **params)
    end
    assert_match message, error.message
  end

  def assert_bad_position(statement, **params)
    assert_error "Variable cannot be used in this position", statement, **params
  end

  def run_statement(statement, format: "csv", **params)
    run_query statement, **params, data_source: data_source, format: format
    CSV.parse(response.body, headers: true).map(&:to_h) if format == "csv"
  end
end
