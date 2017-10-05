require 'net/http'

module Blazer
  class SlackNotifier
    include Rails.application.routes.url_helpers

    def self.state_change(check, state, state_was, rows_count)
      message = "#{check.query.name} check changed status from #{state_was} to #{state}. It now returns #{rows} rows."
      notify_slack(message)
    end

    def self.failing_checks(checks, channel)
      message = "Checks failing.\n"
      checks.each { |c| message << "#{c.query.name} (#{c.state})\n" }
      notify_slack(message)
    end

    def self.notify_slack(message)
      slack_url = ENV.fetch('SLACK_WEBHOOK_URL')

      params = {
        text: message
      }

      uri = URI.parse(slack_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = params.to_json
      http.request(request)
    end
  end
end
