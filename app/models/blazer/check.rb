module Blazer
  class Check < ActiveRecord::Base
    belongs_to :query

    validates :query_id, presence: true

    before_validation :set_state

    def set_state
      self.state ||= "new"
    end

    def split_emails
      emails.to_s.downcase.split(",").map(&:strip)
    end

    def update_state(rows, error)
      invert = respond_to?(:invert) && self.invert
      self.state =
        if error
          if error == Blazer::TIMEOUT_MESSAGE
            "timed out"
          else
            "error"
          end
        elsif rows.any?
          invert ? "passing" : "failing"
        else
          invert ? "failing" : "passing"
        end

      self.last_run_at = Time.now if respond_to?(:last_run_at=)

      if respond_to?(:timeouts=)
        if state == "timed out"
          self.timeouts += 1
          self.state = "disabled" if timeouts >= 3
        else
          self.timeouts = 0
        end
      end

      # do not notify on creation, except when not passing
      if (state_was || state != "passing") && state != state_was && emails.present?
        Blazer::CheckMailer.state_change(self, state, state_was, rows.size, error).deliver_later
      end
      save! if changed?
    end
  end
end
