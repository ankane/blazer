module Blazer
  class DashboardQuery < Record

    self.table_name = 'data_alert_dashboard_queries'

    belongs_to :dashboard
    belongs_to :query

    validates :dashboard_id, presence: true
    validates :query_id, presence: true
  end
end
