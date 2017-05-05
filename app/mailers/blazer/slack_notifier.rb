require 'slack-notifier'

module Blazer
  class SlackNotifier
    def state_change(check, state, state_was, rows_count)
      message = "#{check} check changed status from #{state_was} to #{state}. It now returns #{rows} rows. #{query_url(check.query_id)}"
      notifier.ping(message)
    end

    def failing_checks(checks)
      msg = "#{pluralize(checks.size, "Check")} failing.\n"
      checks.each { |c| msg << "#{query_url(check.query_id)} (#{check.state})" }
      notifier.ping(msg)
    end

    def notifier
      Slack::Notifier.new ENV.fetch('WEBHOOK_URL'), channel: ENV.fetch('SLACK_CHANNEL'),
                                                    username: ENV.fetch('SLACK_USERNAME')
    end
  end
end
