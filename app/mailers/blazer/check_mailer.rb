require 'slack-notifier'

module Blazer
  class CheckMailer < ActionMailer::Base
    include ActionView::Helpers::TextHelper

    default from: Blazer.from_email if Blazer.from_email
    layout false

    def state_change(check, state, state_was, rows_count, error, columns, rows, column_types, check_type)
      @check = check
      @state = state
      @state_was = state_was
      @rows_count = rows_count
      @error = error
      @columns = columns
      @rows = rows
      @column_types = column_types
      @check_type = check_type
      notify_slack(check.query.name)
      mail to: check.emails, reply_to: check.emails, subject: "Check #{state.titleize}: #{check.query.name}"
    end

    def failing_checks(email, checks)
      @checks = checks
      notify_slack("about security")
      # add reply_to for mailing lists
      mail to: email, reply_to: email, subject: "#{pluralize(checks.size, "Check")} Failing"
    end

    def notify_slack(name)
      notifier = Slack::Notifier.new ENV.fetch('WEBHOOK_URL'), channel: '#info-production',
                                                               username: 'Blazer Notifier'

      notifier.ping "Check #{name} failing. http://107.170.251.230/queries/52-unrecognized-priviliged-user @etavenn @skatkov @channel"
    end
  end
end
