module Blazer
  class Check < ActiveRecord::Base
    belongs_to :creator, Blazer::BELONGS_TO_OPTIONAL.merge(class_name: Blazer.user_class.to_s) if Blazer.user_class
    belongs_to :query

    validates :query_id, presence: true

    before_validation :set_state
    before_validation :fix_emails
    before_validation :fix_slack_channels

    def split_emails
      emails.to_s.downcase.split(",").map(&:strip)
    end

    def split_slack_channels
      slack_channels.to_s.downcase.split(",").map(&:strip)
    end

    def update_state(result)
      check_type =
        if respond_to?(:check_type)
          self.check_type
        elsif respond_to?(:invert)
          invert ? "missing_data" : "bad_data"
        else
          "bad_data"
        end

      message = result.error

      self.state =
        if result.timed_out?
          "timed out"
        elsif result.error
          "error"
        elsif check_type == "anomaly"
          anomaly, message = result.detect_anomaly
          if anomaly.nil?
            "error"
          elsif anomaly
            "failing"
          else
            "passing"
          end
        elsif result.rows.any?
          check_type == "missing_data" ? "passing" : "failing"
        else
          check_type == "missing_data" ? "failing" : "passing"
        end

      self.last_run_at = Time.now if respond_to?(:last_run_at=)
      self.message = message if respond_to?(:message=)

      if respond_to?(:timeouts=)
        if result.timed_out?
          self.timeouts += 1
          self.state = "disabled" if timeouts >= 3
        else
          self.timeouts = 0
        end
      end

      # do not notify on creation, except when not passing
      if notify?
        Blazer::CheckMailer.state_change(self, state, state_was, result.rows.size, message, result.columns, result.rows.first(10).as_json, result.column_types, check_type).deliver_later

        uri = URI(Blazer.slack_incoming_webhook_url)
        host = "#{ActionMailer::Base.default_url_options[:host]}:#{ActionMailer::Base.default_url_options[:port]}"
        url = Blazer::Engine.routes.url_helpers.query_url(query, host: host)

        state_color_map = {
          "passing" => "#008000", # green
          "disabled" => "#000000", # black
          "failed" => "#ff0000", # red
          "timed out" => "#ffa500", # orange
          "error" => "#ff0000" # red
        }
        color = state_color_map[state]
        split_slack_channels.each do |slack_channel|
          json = {
            channel: slack_channel,
            username: "Blazer",
            color: color,
            pretext: "<#{url}|Check #{state.titleize}: #{query.name}>",
            text: "#{ActionController::Base.helpers.pluralize(result.rows.size, "Row")}",
            icon_emoji: ":tangerine:"
          }.to_json
          res = Net::HTTP.post_form(uri, payload: json)
        end
      end
      save! if changed?
    end

    private

      def notify?
        send_it = true
        send_it &&= (emails.present? || slack_channels.present?)

        # Do not notify if the state has not changed
        send_it &&= (state != state_was)

        error_states = ["error", "timed out"]

        # Do not notify on creation, except when not passing
        send_it &&= (state_was != "new" || state != "passing")

        if self.respond_to?(:notify_on_error)
          # Do not notify on error when notify_on_error is false
          send_it &&= (!state.in?(error_states) || notify_on_error)

          # Do not send on passing when notify_on_pass is false, or when notify_on_pass is true but
          # the previous state was 'error' and notify_on_error is false.
          send_it &&= (state != "passing" || (notify_on_pass && (!state_was.in?(error_states) || notify_on_error)))
        end

        send_it
      end

      def set_state
        self.state ||= "new"
      end

      def fix_emails
        # some people like doing ; instead of ,
        # but we know what they mean, so let's fix it
        self.emails = emails.gsub(";", ",") if emails.present?
      end

      def fix_slack_channels
        # some people like doing ; instead of ,
        # but we know what they mean, so let's fix it
        self.slack_channels = slack_channels.gsub(";", ",") if slack_channels.present?
      end
  end
end
