module Blazer
  class Audit < ActiveRecord::Base
    belongs_to :user
    belongs_to :query
  end
end
