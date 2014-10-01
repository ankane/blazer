module Blazer
  class Audit < ActiveRecord::Base
    belongs_to :user
  end
end
