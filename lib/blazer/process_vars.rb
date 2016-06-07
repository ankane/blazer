module Blazer
  module ProcessVars
    def process_vars(statement, data_source)
      (@bind_vars ||= []).concat(extract_vars(statement)).uniq!
      @bind_vars.each do |var|
        params[var] ||= Blazer.data_sources[data_source].variable_defaults[var]
      end
      @success = @bind_vars.all? { |v| params[v] }

      if @success
        @bind_vars.each do |var|
          value = params[var].presence
          if value
            if value =~ /\A\d+\z/
              value = value.to_i
            elsif value =~ /\A\d+\.\d+\z/
              value = value.to_f
            end
          end
          if var.end_with?("_at")
            value = Blazer.time_zone.parse(value) rescue nil
          end
          value.gsub!(" ", "+") if ["start_time", "end_time"].include?(var) # fix for Quip bug
          statement.gsub!("{#{var}}", ActiveRecord::Base.connection.quote(value))
        end
      end
    end

    def extract_vars(statement)
      # strip commented out lines
      # and regex {1} or {1,2}
      statement.gsub(/\-\-.+/, "").gsub(/\/\*.+\*\//m, "").scan(/\{.*?\}/).map { |v| v[1...-1] }.reject { |v| /\A\d+(\,\d+)?\z/.match(v) }.uniq
    end
  end
end
