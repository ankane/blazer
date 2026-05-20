module Blazer
  class Check < Record
    belongs_to :creator, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class
    belongs_to :query

    validates :query_id, presence: true
    validate :validate_emails
    validate :validate_variables, if: -> { query_id_changed? }

    before_validation :set_state
    before_validation :fix_emails

    def update_state(result)
      check_type = computed_check_type

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
        elsif check_type == "missing_data"
          result.rows.any? ? "passing" : "failing"
        else # bad_data
          result.rows.any? ? "failing" : "passing"
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
      if (state_was != "new" || state != "passing") && state != state_was
        Blazer.notifiers.each do |notifier|
          notifier.state_change(check: self, state:, state_was:, result:, message:, check_type:)
        end
      end
      save! if changed?
    end

    def computed_check_type
      if respond_to?(:check_type)
        check_type
      elsif respond_to?(:invert)
        invert ? "missing_data" : "bad_data"
      else
        "bad_data"
      end
    end

    private

    def set_state
      self.state ||= "new"
    end

    # TODO rename
    def fix_emails
      Blazer.notifiers.each do |notifier|
        notifier.before_validation(self) if notifier.respond_to?(:before_validation)
      end
    end

    # TODO rename
    def validate_emails
      Blazer.notifiers.each do |notifier|
        notifier.validate(self) if notifier.respond_to?(:validate)
      end
    end

    def validate_variables
      if query && query.variables.any?
        errors.add(:base, "Query can't have variables")
      end
    end
  end
end
