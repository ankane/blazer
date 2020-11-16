namespace :blazer do
  desc "run checks"
  task :run_checks, [:schedule] => :environment do |_, args|
    Blazer.run_checks(schedule: args[:schedule] || ENV["SCHEDULE"])
  end

  desc "send failing checks"
  task send_failing_checks: :environment do
    Blazer.send_failing_checks
  end

  desc "archive queries"
  task archive_queries: :environment do
    abort "Audits must be enabled to archive" unless Blazer.audit
    abort "Missing status column - see https://github.com/ankane/blazer#23" unless Blazer::Query.column_names.include?("status")

    viewed_query_ids = Blazer::Audit.where("created_at > ?", 90.days.ago).group(:query_id).count.keys.compact
    Blazer::Query.active.where.not(id: viewed_query_ids).update_all(status: "archived")
  end
end
