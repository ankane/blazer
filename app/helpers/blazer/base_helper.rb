module Blazer
  module BaseHelper
    def blazer_title(title = nil)
      if title
        content_for(:title) { title }
      else
        content_for?(:title) ? content_for(:title) : nil
      end
    end

    BLAZER_URL_REGEX = /\Ahttps?:\/\/[\S]+\z/
    BLAZER_IMAGE_EXT = %w[png jpg jpeg gif]

    def blazer_format_value(key, value)
      if value.is_a?(Numeric) && !key.to_s.end_with?("id") && !key.to_s.start_with?("id")
        number_with_delimiter(value)
      elsif value.is_a?(String) && value =~ BLAZER_URL_REGEX
        # see if image or link
        if Blazer.images && (key.include?("image") || BLAZER_IMAGE_EXT.include?(value.split(".").last.split("?").first.try(:downcase)))
          link_to value, target: "_blank" do
            image_tag value, referrerpolicy: "no-referrer"
          end
        else
          link_to value, value, target: "_blank"
        end
      else
        value
      end
    end

    def blazer_js_var(name, value)
      "var #{name} = #{json_escape(value.to_json(root: false))};".html_safe
    end

    def blazer_series_name(k)
      k.nil? ? "null" : k.to_s
    end

    def blazer_format_annotations(annotations)
      return [] unless annotations.is_a?(Array)
      sorted = annotations.sort_by { |annotation| annotation[:min_date] }

      boxes = sorted.select { |annotation| annotation[:max_date] }.map.with_index do |annotation, index|
        {
          type: "box",
          xScaleID: "x-axis-0",
          xMin: annotation[:min_date],
          xMax: annotation[:max_date],
          backgroundColor: blazer_map_annotation_box_colors(index),
        }
      end

      # chartjs annotations don't support labels for box annotations
      labels = sorted.select { |annotation| annotation[:label] }.map.with_index do |annotation, index|
        {
          type: "line",
          value: annotation[:min_date],
          mode: "vertical",
          scaleID: "x-axis-0",
          borderColor: '#00000050',
          drawTime: "afterDatasetsDraw",
          label: {
            content: annotation[:label],
            enabled: true,
            position: "bottom",
            yAdjust: 30 + (index * 30) % 60,
          },
        }
      end

      boxes + labels
    end

    private

    def blazer_map_annotation_box_colors(index)
      colors = ['#aec7e8', '#ffbb78', '#98df8a', '#ff9896', '#c5b0d5', '#c49c94', '#f7b6d2', '#c7c7c7', '#dbdb8d', '#9edae5']
      colors[index % colors.size] + 'da'
    end
  end
end

