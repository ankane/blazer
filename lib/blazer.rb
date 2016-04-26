require "csv"
require "yaml"
require "chartkick"
require "blazer/version"
require "blazer/data_source"
require "blazer/engine"
require "blazer/tasks"

module Blazer
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
  end
  self.audit = true
  self.user_name = :name

  TIMEOUT_MESSAGE = "Query timed out :("

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

  def self.run_checks
    Blazer::Check.includes(:query).find_each do |check|
      rows = nil
      error = nil
      tries = 0
      # try 3 times on timeout errors
      while tries < 3
        rows, error, cached_at = data_sources[check.query.data_source].run_statement(check.query.statement, refresh_cache: true)
        if error == Blazer::TIMEOUT_MESSAGE
          Rails.logger.info "[blazer timeout] query=#{check.query.name}"
          tries += 1
          sleep(10)
        else
          break
        end
      end
      check.update_state(rows, error)
      # TODO use proper logfmt
      Rails.logger.info "[blazer check] query=#{check.query.name} state=#{check.state} rows=#{rows.try(:size)} error=#{error}"
    end
  end

  def self.send_failing_checks
    emails = {}
    Blazer::Check.includes(:query).where(state: %w[failing error]).find_each do |check|
      check.split_emails.each do |email|
        (emails[email] ||= []) << check
      end
    end

    emails.each do |email, checks|
      Blazer::CheckMailer.failing_checks(email, checks).deliver_later
    end
  end
end
