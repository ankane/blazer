require 'test_helper'

if ENV['WITH_SQLSERVER']

  # RUNTIME NOTICE!
  # To run this set of tests, include the environment var: WITH_SQLSERVER
  #
  # WITH_SQLSERVER=true bundle exec rake test

  # You'll need to configure a MS SQL Server instance to query against.
  # Either set environment var:
  #   ENV['BLAZER_DATABASE_URL'] = 'sqlserver://rails:railspassword@localhost/master'
  # or edit the file at:
  #   blazer/test/dummy/config/blazer.yml
  #
  #
  # If you don't have one handy, you can use docker to get set up quick.
  # https://hub.docker.com/r/microsoft/mssql-server-linux/
  #
  # docker run -e ACCEPT_EULA=Y -e SA_PASSWORD=GreatPassword! -p 1433:1433 --rm microsoft/mssql-server-linux
  #
  # To test:
  # BLAZER_DATABASE_URL=sqlserver://sa:GreatPassword\!@localhost/master WITH_SQLSERVER=true bundle exec rake test
  #
  # This workflow should get docker-composed but there are problems
  #   with waiting for SQL Server to be available.

  class SqlServerAdapterTest < ActiveSupport::TestCase
    def setup
      @adapter = Blazer::Adapters::SqlServerAdapter.new(Blazer.data_sources["mssqlserver"])
    end

    test 'setup with a datasource' do
      assert_kind_of Blazer::Adapters::SqlServerAdapter, @adapter
    end

    test '#tables' do
      tables = @adapter.tables
      assert tables.count > 0, "Didn't find any tables. Do you have a SQL Server configured with tables? If yes, this fails."
      assert_kind_of String, tables.first
    end

    test '#schema' do
      # require 'pry'
      # binding.pry
      a_schema = @adapter.schema.first
      assert_not_nil a_schema[:table], "Didn't seem to find an expected entry in the schema list. Do you have a SQL Server configured with tables? If yes, this fails."
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
