require "rake"

namespace :blazer do
  desc "run checks"
  task run_checks: :environment do
    Blazer.run_checks
  end

  task send_failing_checks: :environment do
    Blazer.send_failing_checks
  end
end
