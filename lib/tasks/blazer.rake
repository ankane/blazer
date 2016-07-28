namespace :blazer do
  desc "run checks"
  task :run_checks, [:schedule] => :environment do |t, args|
    Blazer.run_checks(schedule: args[:schedule] || ENV["SCHEDULE"])
  end

  task send_failing_checks: :environment do
    Blazer.send_failing_checks
  end
end
