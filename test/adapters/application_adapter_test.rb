require 'test_helper'
require 'application_adapter'

class ApplicationAdapterTest < Minitest::Test

  TEST_FORMAT_ADAPTER_FORMAT = :test

  class TestAdapter < ApplicationAdapter
    class << self

      def format
        TEST_FORMAT_ADAPTER_FORMAT
      end

    end
  end

  def test_can_instanciate
    adapter = ApplicationAdapter.new(nil, nil, nil, nil)

    refute_nil adapter
  end

  def test_can_set_attributes_on_initialization
    query = 'query'
    columns = 'columns'
    rows = 'rows'
    data_source = 'data_source'
    adapter = ApplicationAdapter.new(query, columns, rows, data_source)

    assert_equal query, adapter.instance_variable_get(:@query)
    assert_equal columns, adapter.instance_variable_get(:@columns)
    assert_equal rows, adapter.instance_variable_get(:@rows)
    assert_equal data_source, adapter.instance_variable_get(:@data_source)
  end

  def test_can_set_format_when_class_method_overrided
    adapter = TestAdapter.new(nil, nil, nil, nil)

    assert_equal TEST_FORMAT_ADAPTER_FORMAT, adapter.format
  end

  def test_cannot_rewrite_attributes_from_outside
    adapter = TestAdapter.new(nil, nil, nil, nil)

    assert_raises(NoMethodError) { adapter.format = :bad_format }
    assert_raises(NoMethodError) { adapter.render_method = :bad_render_method }
    assert_equal TEST_FORMAT_ADAPTER_FORMAT, adapter.format
    assert_nil adapter.render_method
  end

end
