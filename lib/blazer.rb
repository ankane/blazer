require "csv"
require "chartkick"
require "blazer/version"
require "blazer/engine"
require "blazer/tasks"

module Blazer
  class << self
    attr_accessor :audit
    attr_reader :time_zone
    attr_accessor :user_name
    attr_accessor :user_class
    attr_accessor :timeout
    attr_accessor :from_email
  end
  self.audit = true
  self.user_name = :name
  self.timeout = 15

  def self.time_zone=(time_zone)
    @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
  end

  def self.settings
    @settings ||= YAML.load(File.read(Rails.root.join("config", "blazer.yml")))
  end

  def self.linked_columns
    settings["linked_columns"] || {}
  end

  def self.smart_columns
    settings["smart_columns"] || {}
  end

  def self.smart_variables
    settings["smart_variables"] || {}
  end

  def self.run_statement(statement)
    rows = []
    error = nil
    begin
      Blazer::Connection.transaction do
        Blazer::Connection.connection.execute("SET statement_timeout = #{Blazer.timeout * 1000}") if Blazer.timeout && postgresql?
        result = Blazer::Connection.connection.select_all(statement)
        result.each do |untyped_row|
          row = {}
          untyped_row.each do |k, v|
            row[k] = result.column_types.empty? ? v : result.column_types[k].send(:type_cast, v)
          end
          rows << row
        end
        raise ActiveRecord::Rollback
      end
    rescue ActiveRecord::StatementInvalid => e
      error = e.message.sub(/.+ERROR: /, "")
    end
    [rows, error]
  end

  def self.tables
    default_schema = postgresql? ? "public" : Blazer::Connection.connection_config[:database]
    schema = Blazer::Connection.connection_config[:schema] || default_schema
    rows, error = run_statement(Blazer::Connection.send(:sanitize_sql_array, ["SELECT table_name, column_name, ordinal_position, data_type FROM information_schema.columns WHERE table_schema = ?", schema]))
    Hash[rows.group_by { |r| r["table_name"] }.map { |t, f| [t, f.sort_by { |f| f["ordinal_position"] }.map { |f| f.slice("column_name", "data_type") }] }.sort_by { |t, _f| t }]
  end

  def self.postgresql?
    Blazer::Connection.connection.adapter_name == "PostgreSQL"
  end

  def self.run_checks
    Blazer::Check.includes(:blazer_query).find_each do |check|
      rows, error = run_statement(check.blazer_query.statement)
      check.update_state(rows, error)
    end
  end

  def self.send_failing_checks
    emails = {}
    Blazer::Check.includes(:blazer_query).where(state: %w[failing error]).find_each do |check|
      check.split_emails.each do |email|
        (emails[email] ||= []) << check
      end
    end

    emails.each do |email, checks|
      Blazer::CheckMailer.failing_checks(email, checks).deliver_later
    end
  end
end
