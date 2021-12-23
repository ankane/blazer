source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "combustion"
gem "rails"
gem "pg"
gem "sprockets-rails"

# data sources
gem "elasticsearch"
gem "mysql2"

# anomaly detection and forecasting
gem "prophet-rb" if ENV["TEST_PROPHET"]
gem "trend" if ENV["TEST_TREND"]
