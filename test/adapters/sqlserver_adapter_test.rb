require 'test_helper'

if ENV['WITH_SQLSERVER']

  # To run this set of tests, include the environment var: WITH_SQLSERVER
  # e.g. => WITH_SQLSERVER=true bundle exec rake test
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
      # require 'pry'
      # binding.pry
      a_schema = @adapter.schema.select {|s| s[:table] == 'ROBOT_MESSAGE' && s[:columns].first[:name] == "ID"}
      assert_not_nil a_schema, "Didn't seem to find an expected entry in the schema list."
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

end
