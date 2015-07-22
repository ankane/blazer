module Blazer
  class Query < ActiveRecord::Base
    validates :name, presence: true
    validates :statement, presence: true

    def to_param
      [id, name.gsub("'", "").parameterize].join("-")
    end
  end
end
