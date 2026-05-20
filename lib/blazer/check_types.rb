Blazer.register_check_type "bad_data", "Any results (bad data)" do |result|
  result.rows.any? ? "failing" : "passing"
end

Blazer.register_check_type "missing_data", "No results (missing data" do |result|
  result.rows.any? ? "passing" : "failing"
end

Blazer.register_check_type "anomaly", "Anomaly (most recent data point)" do |result|
  anomaly, message = result.detect_anomaly
  state =
    if anomaly.nil?
      "error"
    elsif anomaly
      "failing"
    else
      "passing"
    end
  [state, message]
end
