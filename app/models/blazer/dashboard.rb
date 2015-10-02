module Blazer
  class Dashboard < ActiveRecord::Base
    has_many :dashboard_queries, dependent: :destroy
    has_many :queries, through: :dashboard_queries

    validates :name, presence: true

    def to_param
      [id, name.gsub("'", "").parameterize].join("-")
    end
  end
end
