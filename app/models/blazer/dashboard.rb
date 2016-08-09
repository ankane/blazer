module Blazer
  class Dashboard < ActiveRecord::Base
    belongs_to :creator, Blazer::BELONGS_TO_OPTIONAL.merge(class_name: Blazer.user_class.to_s) if Blazer.user_class
    has_many :dashboard_queries, dependent: :destroy
    has_many :queries, through: :dashboard_queries

    validates :name, presence: true

    def to_param
      [id, name.gsub("'", "").parameterize].join("-")
    end
  end
end
