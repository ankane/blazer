module Blazer
  class Check < ActiveRecord::Base
    belongs_to :query

    validates :query_id, presence: true

    def split_emails
      emails.to_s.split(",").map(&:strip)
    end

    def update_state(rows, error)
      self.state =
        if error
          "error"
        elsif rows.any?
          invert ? "passing" : "failing"
        else
          invert ? "failing" : "passing"
        end

      # do not notify on creation, except when not passing
      if (state_was || state != "passing") && state != state_was && emails.present?
        Blazer::CheckMailer.state_change(self, state, state_was, rows.size, error).deliver_later
      end
      save! if changed?
    end
  end
end
