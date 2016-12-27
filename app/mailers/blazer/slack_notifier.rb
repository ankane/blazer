require 'slack-notifier'

module Blazer
  class SlackNotifier
    def state_change(check, state, state_was, rows_count)
      message = "#{check} check changed status from #{state_was} to #{state}. It now returns #{rows} rows. #{query_url(check.query_id)}"
      notify_slack(message, check.slack_channel)
    end

    def failing_checks(checks)
      message = "#{pluralize(checks.size, "Check")} failing.\n"
      checks.each { |c| message << "#{query_url(check.query_id)} (#{check.state})" }
      notify_slack(message, checks.first.slack_channel)
    end

    def notify_slack(message, channel)
      notifier(channel).ping(message)
    end

    def notifier(channel)
      Slack::Notifier.new ENV.fetch('WEBHOOK_URL'), channel: channel,
                                                    username: 'Blazer Notifier'
    end
  end
end
