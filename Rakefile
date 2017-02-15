require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.name = :test
  t.libs << "test"
  t.libs << "app/adapters"
  t.test_files = FileList['test/**/*_test.rb']
end
