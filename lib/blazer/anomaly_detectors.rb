Blazer.register_anomaly_detector "anomaly_detection" do |series|
  anomalies = AnomalyDetection.detect(series.to_h, period: :auto)
  anomalies.include?(series.last[0])
end

Blazer.register_anomaly_detector "prophet" do |series|
  df = Rover::DataFrame.new(series[0..-2].map { |v| {"ds" => v[0], "y" => v[1]} })
  m = Prophet.new(interval_width: 0.99)
  m.logger.level = ::Logger::FATAL # no logging
  m.fit(df)
  future = Rover::DataFrame.new(series[-1..-1].map { |v| {"ds" => v[0]} })
  forecast = m.predict(future).to_a[0]
  lower = forecast["yhat_lower"]
  upper = forecast["yhat_upper"]
  value = series.last[1]
  value < lower || value > upper
end

Blazer.register_anomaly_detector "trend" do |series|
  anomalies = Trend.anomalies(series.to_h)
  anomalies.include?(series.last[0])
end
