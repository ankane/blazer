module Blazer
  class Check < ActiveRecord::Base
    belongs_to :creator, Blazer::BELONGS_TO_OPTIONAL.merge(class_name: Blazer.user_class.to_s) if Blazer.user_class
    belongs_to :query

    validates :query_id, presence: true

    before_validation :set_state
    before_validation :fix_emails

    def split_emails
      emails.to_s.downcase.split(",").map(&:strip)
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
      if (state_was != "new" || state != "passing") && state != state_was && emails.present?
        Blazer::CheckMailer.state_change(self, state, state_was, result.rows.size, message, result.columns, result.rows.first(10).as_json, result.column_types, check_type).deliver_later
      end
      save! if changed?
    end

    private

      def set_state
        self.state ||= "new"
      end

      def fix_emails
        # some people like doing ; instead of ,
        # but we know what they mean, so let's fix it
        self.emails = emails.gsub(";", ",") if emails.present?
      end
  end
end
