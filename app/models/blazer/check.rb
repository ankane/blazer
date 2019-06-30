require 'tty-table' if Blazer.slack_app_token
module Blazer
  class Check < Record
    belongs_to :creator, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class
    belongs_to :query

    validates :query_id, presence: true
    validate :validate_emails
    validate :validate_variables, if: -> { query_id_changed? }

    before_validation :set_state
    before_validation :fix_emails

    SQL_CHAR_LIMIT = 3000

    def split_emails
      emails.to_s.downcase.split(",").map(&:strip)
    end

    def split_slack_channels
      if Blazer.slack?
        slack_channels.to_s.downcase.split(",").map(&:strip)
      else
        []
      end
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
      if state!='passing' && Blazer.slack_app_token
        column_limit= 8
        display_rows=[]
        result.rows.each {|x|  display_rows<< x.try(:first,column_limit)}
        display_columns = result.columns.try(:first,column_limit)
        width = (73.0 - display_columns.size)/display_columns.size
        width_array = [width]*display_columns.size
        begin
          self.failed_table = (TTY::Table.new header: display_columns, rows: display_rows).render(:ascii, column_widths: width_array,multiline: true)[0,SQL_CHAR_LIMIT] #4000 include all slack string limitation
        rescue => e
          self.failed_table = "Failed to render Table: #{e}"
        end
      end
      # do not notify on creation, except when not passing
      if (state_was != "new" || state != "passing") && state != state_was && emails.present?
        Blazer::CheckMailer.state_change(self, state, state_was, result.rows.size, message, result.columns, result.rows.first(10).as_json, result.column_types, check_type).deliver_now
        Blazer::SlackNotifier.state_change(self, state, state_was, result.rows.size, message, check_type)
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
        # also, some people like to use whitespace
        if emails.present?
          self.emails = emails.strip.gsub(/[;\s]/, ",").gsub(/,+/, ", ")
        end
      end

      def validate_emails
        unless split_emails.all? { |e| e =~ /\A\S+@\S+\.\S+\z/ }
          errors.add(:base, "Invalid emails")
        end
      end

      def validate_variables
        if query.variables.any?
          errors.add(:base, "Query can't have variables")
        end
      end
  end
end
