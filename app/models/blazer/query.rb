module Blazer
  class Query < Record
    belongs_to :creator, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class
    has_many :checks, dependent: :destroy
    has_many :dashboard_queries, dependent: :destroy
    has_many :dashboards, through: :dashboard_queries
    has_many :audits

    validates :statement, presence: true

    scope :active, -> { column_names.include?("status") ? where(status: "active") : all }
    scope :named, -> { where.not(name: "") }

    def to_param
      [id, name].compact.join("-").gsub("'", "").parameterize
    end

    def friendly_name
      name.to_s.sub(/\A[#\*]/, "").gsub(/\[.+\]/, "").strip
    end

    def viewable?(user)
      if Blazer.query_viewable
        Blazer.query_viewable.call(self, user)
      else
        true
      end
    end

    def editable?(user)
      editable = !persisted? || (name.present? && name.first != "*" && name.first != "#") || user == try(:creator)
      editable &&= viewable?(user)
      editable &&= Blazer.query_editable.call(self, user) if Blazer.query_editable
      editable
    end

    def variables
      variables = Blazer.extract_vars(statement)
      variables += ["cohort_period"] if cohort_analysis?
      variables
    end

    def cohort_analysis?
      /\/\*\s*cohort analysis\s*\*\//i.match?(statement)
    end
  end
end
