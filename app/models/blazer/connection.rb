module Blazer
  class Connection < ActiveRecord::Base
    establish_connection ENV["BLAZER_DATABASE_URL"] if ENV["BLAZER_DATABASE_URL"]
  end
end
