require 'test_helper'
require 'send_data_adapter'

class SendDataAdapterTest < Minitest::Test

  class TestAdapter < SendDataAdapter

    class << self
      def format
        ADAPTER_FORMAT
      end
    end

    protected

    def disposition
      "attachment; filename=\"#{filename}\""
    end

    def mime_type
      ADAPTER_MIME_TYPE
    end

    def charset
      ADAPTER_CHARSET
    end

    def file_content
      ADAPTER_FILE_CONTENT
    end

    def filename
      ADAPTER_FILENAME
    end

  end

  ADAPTER_FORMAT = :test
  ADAPTER_FILENAME = 'test.test'.freeze
  ADAPTER_CHARSET = 'test'.freeze
  ADAPTER_FILE_CONTENT = 'test'.freeze
  ADAPTER_MIME_TYPE = 'text/test'.freeze
  RENDER_METHOD = :send_data

  def test_can_instanciate
    adapter = SendDataAdapter.new(nil, nil, nil, nil)

    refute_nil adapter
  end

  def test_overrides_render_method
    adapter = SendDataAdapter.new(nil, nil, nil, nil)

    assert_equal RENDER_METHOD, adapter.render_method
  end

  def test_can_still_set_attributes_on_initialization
    query = 'query'
    columns = 'columns'
    rows = 'rows'
    data_source = 'data_source'
    adapter = SendDataAdapter.new(query, columns, rows, data_source)

    assert_equal query, adapter.instance_variable_get(:@query)
    assert_equal columns, adapter.instance_variable_get(:@columns)
    assert_equal rows, adapter.instance_variable_get(:@rows)
    assert_equal data_source, adapter.instance_variable_get(:@data_source)
  end

  def test_can_override_methods
    adapter = TestAdapter.new(nil, nil, nil, nil)

    assert_equal ADAPTER_FORMAT, adapter.format
    assert_equal ADAPTER_FILENAME, adapter.send(:filename)
    assert_equal ADAPTER_CHARSET, adapter.send(:charset)
    assert_equal ADAPTER_FILE_CONTENT, adapter.send(:file_content)
    assert_equal ADAPTER_MIME_TYPE, adapter.send(:mime_type)
    assert_equal "attachment; filename=\"#{ADAPTER_FILENAME}\"", adapter.send(:disposition)
  end

end
