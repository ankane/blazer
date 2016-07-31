require "csv"
require "yaml"
require "chartkick"
require "safely/core"
require "react-rails"
require "js-routes"
require "blazer/version"
require "blazer/data_source"
require "blazer/result"
require "blazer/run_statement"
require "blazer/adapters/base_adapter"
require "blazer/adapters/elasticsearch_adapter"
require "blazer/adapters/mongodb_adapter"
require "blazer/adapters/presto_adapter"
require "blazer/adapters/sql_adapter"
require "blazer/engine"

module Blazer
  class Error < StandardError; end
  class TimeoutNotSupported < Error; end

  class << self
    attr_accessor :audit
    attr_reader :time_zone
    attr_accessor :user_name
    attr_accessor :user_class
    attr_accessor :user_method
    attr_accessor :before_action
    attr_accessor :from_email
    attr_accessor :cache
    attr_accessor :transform_statement
    attr_accessor :check_schedules
    attr_accessor :anomaly_checks
    attr_accessor :async
    attr_accessor :images
  end
  self.audit = true
  self.user_name = :name
  self.check_schedules = ["5 minutes", "1 hour", "1 day"]
  self.anomaly_checks = false
  self.async = false
  self.images = false

  TIMEOUT_MESSAGE = "Query timed out :("
  TIMEOUT_ERRORS = [
    "canceling statement due to statement timeout", # postgres
    "canceling statement due to conflict with recovery", # postgres
    "cancelled on user's request", # redshift
    "canceled on user's request", # redshift
    "system requested abort", # redshift
    "maximum statement execution time exceeded" # mysql
  ]
  BELONGS_TO_OPTIONAL = {}
  BELONGS_TO_OPTIONAL[:optional] = true if Rails::VERSION::MAJOR >= 5

  def self.time_zone=(time_zone)
    @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
  end

  def self.settings
    @settings ||= begin
      path = Rails.root.join("config", "blazer.yml").to_s
      if File.exist?(path)
        YAML.load(ERB.new(File.read(path)).result)
      else
        {}
      end
    end
  end

  def self.data_sources
    @data_sources ||= begin
      ds = Hash[
        settings["data_sources"].map do |id, s|
          [id, Blazer::DataSource.new(id, s)]
        end
      ]
      ds.default = ds.values.first
      ds
    end
  end

  def self.run_checks(schedule: nil)
    checks = Blazer::Check.includes(:query)
    checks = checks.where(schedule: schedule) if schedule
    checks.find_each do |check|
      next if check.state == "disabled"
      Safely.safely { run_check(check) }
    end
  end

  def self.run_check(check)
    rows = nil
    error = nil
    tries = 1

    ActiveSupport::Notifications.instrument("run_check.blazer", check_id: check.id, query_id: check.query.id, state_was: check.state) do |instrument|
      # try 3 times on timeout errors
      data_source = data_sources[check.query.data_source]
      statement = check.query.statement
      Blazer.transform_statement.call(data_source, statement) if Blazer.transform_statement

      while tries <= 3
        result = data_source.run_statement(statement, refresh_cache: true, check: check, query: check.query)
        if result.timed_out?
          Rails.logger.info "[blazer timeout] query=#{check.query.name}"
          tries += 1
          sleep(10)
        elsif result.error.to_s.start_with?("PG::ConnectionBad")
          data_source.reconnect
          Rails.logger.info "[blazer reconnect] query=#{check.query.name}"
          tries += 1
          sleep(10)
        else
          break
        end
      end
      check.update_state(result)
      # TODO use proper logfmt
      Rails.logger.info "[blazer check] query=#{check.query.name} state=#{check.state} rows=#{result.rows.try(:size)} error=#{result.error}"

      instrument[:statement] = statement
      instrument[:data_source] = data_source
      instrument[:state] = check.state
      instrument[:rows] = result.rows.try(:size)
      instrument[:error] = result.error
      instrument[:tries] = tries
    end
  end

  def self.send_failing_checks
    emails = {}
    Blazer::Check.includes(:query).where(state: ["failing", "error", "timed out", "disabled"]).find_each do |check|
      check.split_emails.each do |email|
        (emails[email] ||= []) << check
      end
    end

    emails.each do |email, checks|
      Blazer::CheckMailer.failing_checks(email, checks).deliver_later
    end
  end
end
