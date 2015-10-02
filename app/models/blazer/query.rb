module Blazer
  class Query < ActiveRecord::Base
    belongs_to :creator, class_name: Blazer.user_class.to_s if Blazer.user_class
    has_many :checks, dependent: :destroy

    validates :name, presence: true
    validates :statement, presence: true

    def to_param
      [id, name.gsub("'", "").parameterize].join("-")
    end

    def friendly_name
      name.gsub(/\[.+\]/, "").strip
    end
  end
end
