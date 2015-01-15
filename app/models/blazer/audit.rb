module Blazer
  class Audit < ActiveRecord::Base
    belongs_to :user, class_name: Blazer.user_class.to_s
    belongs_to :query
  end
end
