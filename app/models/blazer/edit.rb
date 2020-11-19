module Blazer
  class Edit < Record
    belongs_to :user, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class
    belongs_to :editable, polymorphic: true

    serialize :edit_changes, JSON
  end
end
