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

    def primary_secondary_values(row, index)
      return unless row.is_a?(Array) && row.size >= 2

      enom = row[index + 2] || 0
      denom = row[1]

      if @cohort_shape == "right aligned"
        primary = number_with_delimiter(enom)
        secondary = denom > 0 ? "#{(100.0 * enom / denom).round}%" : "-"
      elsif @cohort_shape == "left aligned"
        primary = denom > 0 ? "#{(100.0 * enom / denom).round}%" : "-"
        secondary = number_with_delimiter(enom)
      end

      return primary, secondary, enom, denom
    end

    def cohort_line_chart_data
      return_me = @rows.map do |row|
        denom = row[1]

        {
          name: row[0], 
          data: @columns[0..-1].each_with_index.map { |col, index| 
            [col + ":", ((row[index + 2] * 100.0) / denom).round(1)] if row[index + 2]&.present?
          }.compact
        }
      end

      return_me
    end

    def cohort_stacked_column_chart_data
      stacked_data = {}
      new_volumes = []
      existing_volumes = []

      @columns.each do |column|
        stacked_data[column] = {"New" => 0, "Existing" => 0}
      end

      @rows.each do |row|
        new_volume_added = false

        row[2..-1].each_with_index do |value, index|
          period = @columns[index]

          if value > 0
            if !new_volume_added
              stacked_data[period]["New"] += value
              new_volume_added = true
            else
              stacked_data[period]["Existing"] += value
            end
          end
        end
      end

      stacked_data.each do |period, volumes|
        new_volumes << [period, volumes["New"]]
        existing_volumes << [period, volumes["Existing"]]
      end

      [
        {name: "Existing", data: existing_volumes},
        {name: "New", data: new_volumes}
      ]
    end
  end
end
