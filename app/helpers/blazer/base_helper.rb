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
      if value.is_a?(Integer) && !key.to_s.end_with?("id") && !key.to_s.start_with?("id")
        number_with_delimiter(value)
      elsif value =~ BLAZER_URL_REGEX
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

    def blazer_maps?
      ENV["MAPBOX_ACCESS_TOKEN"].present?
    end

    def blazer_js_var(name, value)
      "var #{name} = #{blazer_json_escape(value.to_json(root: false))};".html_safe
    end

    JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003e', '<' => '\u003c', "\u2028" => '\u2028', "\u2029" => '\u2029' }
    JSON_ESCAPE_REGEXP = /[\u2028\u2029&><]/u

    # Prior to version 4.1 of rails double quotes were inadventently removed in json_escape.
    # This adds the correct json_escape functionality to rails versions < 4.1
    def blazer_json_escape(s)
      if Rails::VERSION::STRING < "4.1"
        result = s.to_s.gsub(JSON_ESCAPE_REGEXP, JSON_ESCAPE)
        s.html_safe? ? result.html_safe : result
      else
        json_escape(s)
      end
    end

    def blazer_series_name(k)
      k.nil? ? "null" : k.to_s
    end

    def vis_timeline(chart_id, rows)
      if rows.first[3].present?
        values = rows.map.with_index(1) { |array, index| { id: index, content: array[0], start: array[1], end: array[2], group: array[3] } }
        groups = rows.map { |array| array[3] }.uniq.map { |group_name| { id: group_name, content: group_name } }
      else
        values = rows.map.with_index(1) { |array, index| { id: index, content: array[0], start: array[1], end: array[2] } }
        groups = []
      end

      if groups.empty?
        return <<~HTML
          <div id="visualization_#{chart_id}"></div>

          <script type="text/javascript">
              // DOM element where the Timeline will be attached
              var container = document.getElementById('visualization_#{chart_id}');

              // Create a DataSet (allows two way data-binding)
              var items = new vis.DataSet(JSON.parse('#{values.to_json}'));

              // Configuration for the Timeline
              var options = {};

              // Create a Timeline
              new vis.Timeline(container, items, options);
          </script>
        HTML
      end

      <<~HTML
        <div id="visualization_#{chart_id}"></div>

        <script type="text/javascript">
            // DOM element where the Timeline will be attached
            var container = document.getElementById('visualization_#{chart_id}');

            // Create a DataSet (allows two way data-binding)
            var items = new vis.DataSet(JSON.parse('#{values.to_json}'));
            var groups = new vis.DataSet(JSON.parse('#{groups.to_json}'));

            // Configuration for the Timeline
            var options = {};

            // Create a Timeline
            new vis.Timeline(container, items, groups, options);
        </script>
      HTML
    end
  end
end
