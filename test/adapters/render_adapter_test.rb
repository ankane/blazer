require 'test_helper'
require 'render_adapter'

class RenderAdapterTest < Minitest::Test

  RENDER_METHOD = :render

  def test_can_instanciate
    adapter = RenderAdapter.new(nil, nil, nil, nil)

    refute_nil adapter
  end

  def test_overrides_render_method
    adapter = RenderAdapter.new(nil, nil, nil, nil)

    assert_equal RENDER_METHOD, adapter.render_method
  end

  def test_can_still_set_attributes_on_initialization
    query = 'query'
    columns = 'columns'
    rows = 'rows'
    data_source = 'data_source'
    adapter = RenderAdapter.new(query, columns, rows, data_source)

    assert_equal query, adapter.instance_variable_get(:@query)
    assert_equal columns, adapter.instance_variable_get(:@columns)
    assert_equal rows, adapter.instance_variable_get(:@rows)
    assert_equal data_source, adapter.instance_variable_get(:@data_source)
  end

end
