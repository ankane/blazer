module Blazer
    module NameValidator
      extend ActiveSupport::Concern

      included do
        before_validation :strip_unwanted_whitespaces

        validates :name, presence: true,
          uniqueness: {
            scope: :creator_id,
            case_sensitive: false,
            message: "already taken for this user."
          }
      end

      private
        def strip_unwanted_whitespaces
          self.name = "#{self.name}".strip
        end
    end
  end