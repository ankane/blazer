module Blazer
  class Audit < Record
    belongs_to :user, Blazer::BELONGS_TO_OPTIONAL.merge(class_name: Blazer.user_class.to_s)
    belongs_to :query, Blazer::BELONGS_TO_OPTIONAL
  end
end
