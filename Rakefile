require "bundler/gem_tasks"
require "rake/testtask"

task default: :test
Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/*_test.rb"
  t.warning = false # mail gem
end

%w(
  athena bigquery cassandra drill druid elasticsearch
  hive ignite influxdb mysql neo4j opensearch
  postgresql presto redshift salesforce snowflake
  soda spark sqlite sqlserver
).each do |adapter|
  namespace :test do
    Rake::TestTask.new(adapter) do |t|
      t.description = "Run tests for #{adapter}"
      t.test_files = FileList["test/adapters/#{adapter}_test.rb"]
      t.warning = false # mail gem
    end
  end
end
