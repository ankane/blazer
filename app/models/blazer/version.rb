module Blazer
  class Version < Record
    belongs_to :user, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class
    belongs_to :versionable, polymorphic: true

    serialize :version_changes, JSON
  end
end
