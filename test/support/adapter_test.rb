module AdapterTest
  def setup
    settings = YAML.load_file("test/support/adapters.yml")
    Blazer.instance_variable_set(:@settings, settings)
  end

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

  def assert_result(expected, statement, **variables)
    assert_equal expected, run_statement(statement, **variables)
  end

  def assert_audit(expected, statement, **variables)
    run_statement(statement, **variables)
    assert_equal expected, Blazer::Audit.last.statement
  end

  def assert_error(message, statement, **variables)
    error = assert_raises(Blazer::Error) do
      run_statement(statement, **variables)
    end
    assert_match message, error.message
  end

  def assert_bad_position(statement, **variables)
    assert_error "Variable cannot be used in this position", statement, **variables
  end

  def run_statement(statement, format: "csv", **variables)
    run_query statement, data_source: data_source, format: format, variables: variables
    CSV.parse(response.body, headers: true).map(&:to_h) if format == "csv"
  end
end
