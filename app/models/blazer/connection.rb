module Blazer
  class Connection < ActiveRecord::Base
    establish_connection Rails.application.secrets[:blazer_database_url] if Rails.application.secrets[:blazer_database_url]
    self.abstract_class = true
  end
end
