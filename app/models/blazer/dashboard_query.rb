module Blazer
  class DashboardQuery < ActiveRecord::Base
    belongs_to :blazer_dashboard, class_name: "Blazer::Dashboard"
    belongs_to :blazer_query, class_name: "Blazer::Query"

    validates :blazer_dashboard_id, presence: true
    validates :blazer_query_id, presence: true
  end
end
