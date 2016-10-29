namespace :blazer do
  desc "run checks"
  task :run_checks, [:schedule] => :environment do |t, args|
    Blazer.run_checks(schedule: args[:schedule] || ENV["SCHEDULE"])
  end

  task send_failing_checks: :environment do
    Blazer.send_failing_checks
  end

  task archive_queries: :environment do
    if Blazer.audit
      viewed_query_ids = Blazer::Audit.where("created_at > ?", 3.months.ago).group(:query_id).count.keys.compact
      Blazer::Query.active.where("id NOT IN (?)", viewed_query_ids).update_all(status: "archived")
    end
  end
end
