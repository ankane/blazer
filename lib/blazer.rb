require "csv"
require "chartkick"
require "blazer/version"
require "blazer/engine"

module Blazer
  class << self
    attr_reader :time_zone
    attr_accessor :audit, :user_name, :user_class, :timeout, :current_user_name
  end
  self.audit = true
  self.user_name = :name
  self.timeout = 15

  def self.time_zone=(time_zone)
    @time_zone = time_zone.is_a?(ActiveSupport::TimeZone) ? time_zone : ActiveSupport::TimeZone[time_zone.to_s]
  end
end
