module Blazer
  class Upload < Record
    belongs_to :creator, optional: true, class_name: Blazer.user_class.to_s if Blazer.user_class

    validates :name, presence: true, uniqueness: true, format: {with: /\A[a-z0-9_]+\z/}

    def table_name
      Blazer.uploads_connection.quote_table_name("#{Blazer.settings["uploads"]["schema"]}.#{name}")
    end
  end
end
