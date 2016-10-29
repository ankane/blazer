module Blazer
  class Query < ActiveRecord::Base
    belongs_to :creator, Blazer::BELONGS_TO_OPTIONAL.merge(class_name: Blazer.user_class.to_s) if Blazer.user_class
    has_many :checks, dependent: :destroy
    has_many :dashboard_queries, dependent: :destroy
    has_many :dashboards, through: :dashboard_queries
    has_many :audits

    validates :statement, presence: true

    scope :named, -> { where("blazer_queries.name <> ''") }

    str_enum :status, [:active, :archived]

    before_save :set_verified

    def to_param
      [id, name].compact.join("-").gsub("'", "").parameterize
    end

    def friendly_name
      name.to_s.sub(/\A[#\*]/, "").gsub(/\[.+\]/, "").strip
    end

    def editable?(user)
      (!persisted? || (name.present? && name.first != "*" && name.first != "#") || user == creator) && (!verified || Blazer.verifier_ids.include?(user.try(:id).to_s))
    end

      private

      def set_verified
        self.verified = name.start_with?("$")
        true
      end
  end
end
