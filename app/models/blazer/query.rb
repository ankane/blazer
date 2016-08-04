module Blazer
  class Query < ActiveRecord::Base
    belongs_to :creator, Blazer::BELONGS_TO_OPTIONAL.merge(class_name: Blazer.user_class.to_s) if Blazer.user_class
    has_many :checks, dependent: :destroy
    has_many :dashboard_queries, dependent: :destroy
    has_many :dashboards, through: :dashboard_queries
    has_many :audits

    validates :statement, presence: true

    scope :named, -> { where("name <> ''") }

    def to_param
      [id, name].compact.join("-").gsub("'", "").parameterize
    end

    def friendly_name
      name.to_s.gsub(/\[.+\]/, "").strip
    end

    def editable?(user)
      editable = !persisted? || (name.present? && name.first != "*") || user == creator
      editable &&= Blazer.query_editable.call(self, user) if Blazer.query_editable
      editable
    end
  end
end
