module Blazer
  class Dashboard < ActiveRecord::Base
    has_many :blazer_dashboard_queries, class_name: "Blazer::DashboardQuery", foreign_key: "blazer_dashboard_id", dependent: :destroy
    has_many :blazer_queries, class_name: "Blazer::Query", through: :blazer_dashboard_queries

    validates :name, presence: true

    def to_param
      [id, name.gsub("'", "").parameterize].join("-")
    end
  end
end
