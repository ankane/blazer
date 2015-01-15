module Blazer
  class Query < ActiveRecord::Base
    belongs_to :creator, class_name: ENV['BLAZER_USER_CLASS_NAME'] || DEFAULT_USER_CLASS_NAME

    validates :name, presence: true
    validates :statement, presence: true

    def to_param
      [id, name.gsub("'", "").parameterize].join("-")
    end

  end
end
