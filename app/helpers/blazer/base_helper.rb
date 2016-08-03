module Blazer
  module BaseHelper
    def blazer_title(title = nil)
      if title
        content_for(:title) { title }
      else
        content_for?(:title) ? content_for(:title) : nil
      end
    end

    def blazer_maps?
      ENV["MAPBOX_ACCESS_TOKEN"].present?
    end
  end
end
