module BlazerJsonEscape
  JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003e', '<' => '\u003c', "\u2028" => '\u2028', "\u2029" => '\u2029' }
  JSON_ESCAPE_REGEXP = /[\u2028\u2029&><]/u

  # Prior to version 4.1 of rails double quotes were inadventently removed in json_escape.
  # This adds the correct json_escape functionality to rails versions < 4.1
  def blazer_json_escape(s)
    if Rails::VERSION::STRING < "4.1"
      result = s.to_s.gsub(JSON_ESCAPE_REGEXP, JSON_ESCAPE)
      s.html_safe? ? result.html_safe : result
    else
      super(s)
    end
  end
end
