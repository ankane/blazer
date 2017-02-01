require 'test_helper'

class SqlServerAdapterTest < ActiveSupport::TestCase
  def setup
    @adapter = Blazer::Adapters::SqlServerAdapter.new(Blazer.data_sources["mssqlserver"])
  end

  test 'setup with a datasource' do
    assert_kind_of Blazer::Adapters::SqlServerAdapter, @adapter
  end

  test '#tables' do
    tables = @adapter.tables
    assert tables.include? "ROBOT_RUN"
  end

  test '#schema' do
    schemas = @adapter.schema
    schema = schema.select {|s| s[:table] == 'ROBOT_MESSAGE' && s[:columns].first[:name] == "ID"}
    assert_not_nil schema, "Didn't seem to find an expected entry in the schema list."
  end

  test '#preview_statement' do
    assert @adapter.preview_statement =~ /SELECT TOP \(?\d+\)?/i
  end

  test '#cost(statement)' do
    assert_raise NotImplementedError do
      @adapter.cost 'SELECT 1'
    end
  end

  test '#explain(statement)' do
    assert_raise NotImplementedError do
      @adapter.explain 'SELECT 1'
    end
  end

  test '#cancel(run_id)' do
    assert @adapter.respond_to? (:cancel)
    skip "Unsure of how to test this..."
  end
end

=begin
      protected

      def select_all(statement)
        connection_model.connection.select_all(statement)
      end

      # seperate from select_all to prevent mysql error
      def execute(statement)
        connection_model.connection.execute(statement)
      end

      def postgresql?
        ["PostgreSQL", "PostGIS"].include?(adapter_name)
      end

      def redshift?
        ["Redshift"].include?(adapter_name)
      end

      def mysql?
        ["MySQL", "Mysql2", "Mysql2Spatial"].include?(adapter_name)
      end

      def adapter_name
        # prevent bad data source from taking down queries/new
        connection_model.connection.adapter_name rescue nil
      end

      def schemas
        default_schema = (postgresql? || redshift?) ? "public" : connection_model.connection_config[:database]
        settings["schemas"] || [connection_model.connection_config[:schema] || default_schema]
      end

      def set_timeout(timeout)
        if postgresql? || redshift?
          execute("SET #{use_transaction? ? "LOCAL " : ""}statement_timeout = #{timeout.to_i * 1000}")
        elsif mysql?
          execute("SET max_execution_time = #{timeout.to_i * 1000}")
        else
          raise Blazer::TimeoutNotSupported, "Timeout not supported for #{adapter_name} adapter"
        end
      end

      def use_transaction?
        settings.key?("use_transaction") ? settings["use_transaction"] : true
      end

      def in_transaction
        connection_model.connection_pool.with_connection do
          if use_transaction?
            connection_model.transaction do
              yield
              raise ActiveRecord::Rollback
            end
          else
            yield
          end
        end
      end
=end
