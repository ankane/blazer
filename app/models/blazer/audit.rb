module Blazer
  class Audit < ActiveRecord::Base
    belongs_to :user, class_name: Blazer.user_class.to_s, required: false
    belongs_to :query, required: false
  end
end
