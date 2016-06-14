require "csv"
require "yaml"
require "chartkick"
require "blazer/version"
require "blazer/data_source"
require "blazer/engine"
require "safely/core"

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
  end
  self.audit = true
  self.user_name = :name
  self.check_schedules = ["5 minutes", "1 hour", "1 day"]
  self.anomaly_checks = false

  TIMEOUT_MESSAGE = "Query timed out :("
  TIMEOUT_ERRORS = [
    "canceling statement due to statement timeout", # postgres
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
        columns, rows, error, cached_at = data_source.run_statement(statement, refresh_cache: true, check: check, query: check.query)
        if error == Blazer::TIMEOUT_MESSAGE
          Rails.logger.info "[blazer timeout] query=#{check.query.name}"
          tries += 1
          sleep(10)
        elsif error.to_s.start_with?("PG::ConnectionBad")
          data_source.reconnect
          Rails.logger.info "[blazer reconnect] query=#{check.query.name}"
          tries += 1
          sleep(10)
        else
          break
        end
      end
      check.update_state(columns, rows, error, data_source)
      # TODO use proper logfmt
      Rails.logger.info "[blazer check] query=#{check.query.name} state=#{check.state} rows=#{rows.try(:size)} error=#{error}"

      instrument[:statement] = statement
      instrument[:data_source] = data_source
      instrument[:state] = check.state
      instrument[:rows] = rows.try(:size)
      instrument[:error] = error
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

  def self.column_types(columns, rows, boom = {})
    columns.each_with_index.map do |k, i|
      v = (rows.find { |r| r[i] } || {})[i]
      if boom[k]
        "string"
      elsif v.is_a?(Numeric)
        "numeric"
      elsif v.is_a?(Time) || v.is_a?(Date)
        "time"
      elsif v.nil?
        nil
      else
        "string"
      end
    end
  end

  def self.chart_type(column_types)
    if column_types.compact.size >= 2 && column_types.compact == ["time"] + (column_types.compact.size - 1).times.map { "numeric" }
      "line"
    elsif column_types == ["time", "string", "numeric"]
      "line2"
    elsif column_types.compact.size >= 2 && column_types == ["string"] + (column_types.compact.size - 1).times.map { "numeric" }
      "bar"
    end
  end

  def self.detect_anomaly(columns, rows, data_source)
    anomaly = nil
    message = nil

    if rows.empty?
      message = "No data"
    else
      boom = self.boom(columns, rows, data_source)
      chart_type = self.chart_type(column_types(columns, rows, boom))
      if chart_type == "line" || chart_type == "line2"
        series = []

        if chart_type == "line"
          columns[1..-1].each_with_index.each do |k, i|
            series << {name: k, data: rows.map{ |r| [r[0], r[i + 1]] }}
          end
        else
          rows.group_by { |r| v = r[1]; (boom[columns[1]] || {})[v.to_s] || v }.each_with_index.map do |(name, v), i|
            series << {name: name, data: v.map { |v2| [v2[0], v2[2]] }}
          end
        end

        current_series = nil
        begin
          anomalies = []
          series.each do |s|
            current_series = s[:name]
            anomalies << s[:name] if anomaly?(s[:data])
          end
          anomaly = anomalies.any?
          if anomaly
            if anomalies.size == 1
              message = "#{anomalies.first} has an anomaly"
            else
              message = "#{anomalies.to_sentence} have an anomaly"
            end
          else
            message = "No anomalies detected"
          end
        rescue => e
          message = "#{current_series}: #{e.message}"
        end
      else
        message = "Bad format"
      end
    end

    [anomaly, message]
  end

  def self.anomaly?(series)
    series = series.reject { |v| v[0].nil? }.sort_by { |v| v[0] }

    csv_str =
      CSV.generate do |csv|
        csv << ["timestamp", "count"]
        series.each do |row|
          csv << row
        end
      end

    timestamps = []
    output = %x[Rscript #{File.expand_path("../blazer/detect_anomalies.R", __FILE__)} #{Shellwords.escape(csv_str)}]
    if output.empty?
      raise "Unknown R error"
    end

    rows = CSV.parse(output, headers: true)
    error = rows.first && rows.first["x"]
    raise error if error

    rows.each do |row|
      timestamps << Time.parse(row["timestamp"])
    end
    timestamps.include?(series.last[0].to_time)
  end

  def self.boom(columns, rows, data_source)
    boom = {}
    columns.each_with_index do |key, i|
      query = data_source.smart_columns[key]
      if query
        values = rows.map { |r| r[i] }.compact.uniq
        columns, rows2, error, cached_at = data_source.run_statement(ActiveRecord::Base.send(:sanitize_sql_array, [query.sub("{value}", "(?)"), values]))
        boom[key] = Hash[rows2.map { |k, v| [k.to_s, v] }]
      end
    end
    boom
  end
end
