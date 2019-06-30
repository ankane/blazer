require "net/http"

module Blazer
  class SlackNotifier

    class << self
      attr_accessor :postMessageUrl
      attr_accessor :updateUrl
      attr_accessor :token
      attr_accessor :username
      attr_accessor :channelUrl
      attr_accessor :groupUrl
    end
    self.postMessageUrl ='https://slack.com/api/chat.postMessage'
    self.updateUrl ='https://slack.com/api/chat.update'
    self.token = Blazer.slack_app_token
    self.username = 'Blazer'
    #get actual channels id
    self.channelUrl = "https://slack.com/api/channels.list?token=#{token}&exclude_archived=true"
    self.groupUrl = "https://slack.com/api/groups.list?token=#{token}&exclude_archived=true"


    def self.state_change(check, state, state_was, rows_count, error, check_type)
      check.split_slack_channels.each do |channel|
        text =
          if error
            error
          elsif rows_count > 0 && check_type == "bad_data"
            pluralize(rows_count, "row")
          elsif state == "passing" && token
            "Check first failed #{Time.at(check[:failed_ts].to_f)} and passed on #{Time.now}"
          else
            ''
          end
        text+= "\n```\n#{check.failed_table}\n```" if check.failed_table
        payload = {
          channel: channel,
          attachments: [
            {
              title: escape("Check #{state.titleize}: #{check.query.name}"),
              title_link: query_url(check.query_id),
              text: escape(text),
              color: state == "passing" ? "good" : "danger"
            }
          ]
        }


        if !token #old way
          post(Blazer.slack_webhook_url, payload)
        elsif state == "passing" && token
          payload[:channel]=find_channel_id(channel)
          update_post(payload,check[:failed_ts])
          check.update(failed_ts: nil)
          check.update(failed_table: nil)
        else
          results = JSON.parse(update_post(payload).body)


          check.update(failed_ts: results['message']['ts'] || results['ts'] )
        end


      end
    end

    def self.failing_checks(channel, checks)
      text =
        checks.map do |check|
          "<#{query_url(check.query_id)}|#{escape(check.query.name)}> #{escape(check.state)}"
        end

      payload = {
        channel: channel,
        attachments: [
          {
            title: escape("#{pluralize(checks.size, "Check")} Failing"),
            text: text.join("\n"),
            color: "warning"
          }
        ]
      }

      post(Blazer.slack_webhook_url, payload)
    end

    # https://api.slack.com/docs/message-formatting#how_to_escape_characters
    # - Replace the ampersand, &, with &amp;
    # - Replace the less-than sign, < with &lt;
    # - Replace the greater-than sign, > with &gt;
    # That's it. Don't HTML entity-encode the entire message.
    def self.escape(str)
      str.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;") if str
    end

    def self.pluralize(*args)
      ActionController::Base.helpers.pluralize(*args)
    end

    def self.query_url(id)
      Blazer::Engine.routes.url_helpers.query_url(id, ActionMailer::Base.default_url_options)
    end

    def self.post(url, payload)
      payload = payload.to_json if payload
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 3
      http.read_timeout = 5
      http.post(uri.request_uri, payload)
    end

    def self.update_post(payload,ts=nil)
      url = ts ? updateUrl : postMessageUrl
      url += '?token='+token
      url += '&username='+username
      url += '&channel='+ payload[:channel]
      url += '&ts='+ ts if ts
      url += '&attachments='+payload[:attachments].to_json
      post(url, nil)
    end
    def self.channel_list
      Blazer.cache.fetch("blazer_channel_list", :expires_in => 1.hour) do
        channels = JSON.parse(post(channelUrl,nil).body)["channels"]
        groups = JSON.parse(post(groupUrl,nil).body)["groups"]
        channels.concat(groups)
      end
    end

    def self.find_channel_id(channel)
      channel_list.find {|c| c['name']==channel}['id']
    end
  end
end
