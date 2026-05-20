module Blazer
  class EmailNotifier
    def self.failing_checks(checks)
      emails = {}
      checks.each do |check|
        split_emails(check).each do |email|
          (emails[email] ||= []) << check
        end
      end
      emails.each do |email, checks|
        Safely.safely do
          Blazer::CheckMailer.failing_checks(email, checks).deliver_now
        end
      end
    end

    def self.state_change(check:, state:, state_was:, result:, message:, check_type:)
      Blazer::CheckMailer.state_change(check, state, state_was, result.rows.size, message, result.columns, result.rows.first(10).as_json, result.column_types, check_type).deliver_now if check.emails.present?
    end

    # TODO improve name
    def self.notify_list(check)
      split_emails(check)
    end

    def self.before_validation(check)
      # some people like doing ; instead of ,
      # but we know what they mean, so let's fix it
      # also, some people like to use whitespace
      if check.emails.present?
        check.emails = check.emails.strip.gsub(/[;\s]/, ",").gsub(/,+/, ", ")
      end
    end

    def self.validate(check)
      unless split_emails(check).all? { |e| e =~ /\A\S+@\S+\.\S+\z/ }
        check.errors.add(:base, "Invalid emails")
      end
    end

    def self.split_emails(check)
      check.emails.to_s.downcase.split(",").map(&:strip)
    end

    def self.fields
      [:emails]
    end
  end
end
