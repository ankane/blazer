module Blazer
  class Audit < ActiveRecord::Base
    belongs_to :user, class_name: ENV['BLAZER_USER_CLASS_NAME'] || DEFAULT_USER_CLASS_NAME
    belongs_to :query
  end
end
