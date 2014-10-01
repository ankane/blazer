module Blazer
  class Query < ActiveRecord::Base
    belongs_to :creator, class_name: "User"

    validates :name, presence: true
    validates :statement, presence: true

    def to_param
      [id, name.remove("'").parameterize].join("-")
    end

  end
end
