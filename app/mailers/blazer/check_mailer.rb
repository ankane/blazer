module Blazer
  class CheckMailer < ActionMailer::Base
    include ActionView::Helpers::TextHelper

    default from: Blazer.from_email if Blazer.from_email

    def state_change(check, state, state_was, rows, error)
      @check = check
      @state = state
      @state_was = state_was
      @rows = rows
      @error = error
      mail to: check.emails, subject: "Check #{state.titleize}: #{check.blazer_query.name}"
    end

    def failing_checks(email, checks)
      @checks = checks
      mail to: email, subject: "#{pluralize(checks.size, "Check")} Failing"
    end
  end
end
