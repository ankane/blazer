source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "combustion"
gem "rails", "~> 7.1.0"
gem "pg"
gem "sprockets-rails"

# data sources
# gem "activerecord6-redshift-adapter"
# gem "aws-sdk-athena"
# gem "aws-sdk-glue"
# gem "cassandra-driver"
# gem "sorted_set"
# gem "drill-sergeant"
# gem "elasticsearch"
# gem "google-cloud-bigquery"
# gem "hexspace"
# gem "ignite-client"
# gem "influxdb"
# gem "mysql2"
# gem "neo4j-core"
# gem "odbc_adapter"
# gem "opensearch-ruby"
# gem "presto-client"
# gem "restforce"
# gem "sqlite3"
# gem "tiny_tds"
# gem "activerecord-sqlserver-adapter"

# anomaly detection and forecasting
gem "anomaly_detection" if ENV["TEST_ANOMALY_DETECTION"]
gem "prophet-rb" if ENV["TEST_PROPHET"]
gem "trend" if ENV["TEST_TREND"]
