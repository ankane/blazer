module Blazer
  class Audit < Record
    self.table_name = 'data_alert_queries'
    
    belongs_to :user, optional: true, class_name: Blazer.user_class.to_s
    belongs_to :query, optional: true
  end
end
