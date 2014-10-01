require "csv"
require "blazer/version"
require "blazer/engine"

module Blazer
  class << self
    attr_accessor :audit
    attr_reader :time_zone
  end
  self.audit = true

  def self.time_zone=(time_zone)
    @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
  end
  self.time_zone = Time.zone
end
