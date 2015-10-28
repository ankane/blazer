module Blazer
  class DashboardQuery < ActiveRecord::Base
    belongs_to :dashboard
    belongs_to :query

    validates :dashboard_id, presence: true
    validates :query_id, presence: true
  end
end
