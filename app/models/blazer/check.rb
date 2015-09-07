module Blazer
  class Check < ActiveRecord::Base
    belongs_to :blazer_query, class_name: "Blazer::Query"

    def update_state(rows, error)
      self.state =
        if error
          "error"
        elsif rows.any?
          "failing"
        else
          "passing"
        end

      # do not notify on creation, except when not passing
      if (state_was || state != "passing") && state != state_was && emails.present?
        Blazer::CheckMailer.state_change(self, state, state_was, rows.size, error).deliver_later
      end
      save!
    end
  end
end
