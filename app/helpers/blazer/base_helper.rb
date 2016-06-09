require 'rails_autolink/helpers'

module Blazer
  module BaseHelper
    def blazer_title(title = nil)
      if title
        content_for(:title) { title }
      else
        content_for?(:title) ? content_for(:title) : nil
      end
    end

    def blazer_format_value(key, value)
      if value.is_a?(Integer) && !key.to_s.end_with?("id")
        number_with_delimiter(value)
      else
        ActionController::Base.helpers.auto_link(value.to_s, link: :urls, html: { target: '_blank' })
      end
    end

    def blazer_column_types(columns, rows, boom)
      columns.each_with_index.map do |k, i|
        v = (rows.find { |r| r[i] } || {})[i]
        if boom[k]
          "string"
        elsif v.is_a?(Numeric)
          "numeric"
        elsif v.is_a?(Time) || v.is_a?(Date)
          "time"
        elsif v.nil?
          nil
        else
          "string"
        end
      end
    end

    def blazer_maps?
      ENV["MAPBOX_ACCESS_TOKEN"].present?
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
  end
end
