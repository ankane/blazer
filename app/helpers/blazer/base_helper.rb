module Blazer
  module BaseHelper
    def title(title = nil)
      if title
        content_for(:title) { title }
      else
        content_for?(:title) ? content_for(:title) : nil
      end
    end

    def format_value(key, value)
      if value.is_a?(Integer) && !key.to_s.end_with?("id")
        number_with_delimiter(value)
      else
        value
      end
    end
  end
end
