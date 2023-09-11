Blazer.register_forecaster "prophet" do |series, count:|
  Prophet.forecast(series, count: count)
end

Blazer.register_forecaster "trend" do |series, count:|
  Trend.forecast(series, count: count)
end
