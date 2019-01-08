## 2.0.1

- Added favicon
- Added search for checks and schema
- Added pie charts
- Added Trend anomaly detection
- Added forecasting
- Improved tooltips
- Improved docs for new installs
- Fixed error with canceling queries

## 2.0.0

- Added support for Slack
- Added `async` option
- Added `override_csp` option
- Added smart variables, linked columns smart columns, and charts to inline docs
- Use SQL for Elasticsearch
- Fixed error with latest `google-cloud-bigquery`

Breaking changes

- Dropped support for Rails < 4.2

## 1.9.0

- Prompt developers to check custom `before_action`
- Better ordering on home page
- Added support for Snowflake

## 1.8.2

- Added support for Cassandra
- Fixes for Druid

## 1.8.1

- Added support for Amazon Athena
- Added support for Druid
- Fixed query cancellation

## 1.8.0

- Added support for Rails 5.1

## 1.7.10

- Added support for Google BigQuery
- Require `drill-sergeant` gem for Apache Drill
- Better handling of checks with variables

## 1.7.9

- Added beta support for Apache Drill
- Added email validation for checks
- Updated Chart.js to 2.5.0

## 1.7.8

- Added support for custom adapters
- Fixed bug with scatter charts on dashboards
- Fixed table preview for SQL Server
- Fixed issue when `default_url_options` set

## 1.7.7

- Fixed preview error for MySQL
- Fixed error with timeouts for MySQL

## 1.7.6

- Added scatter chart
- Fixed issue with false values showing up blank
- Fixed preview for table names with certain characters

## 1.7.5

- Fixed issue with check emails sometimes failing for default Rails 5 ActiveJob adapter
- Fixed sorting for new dashboards

## 1.7.4

- Removed extra dependencies added in 1.7.1
- Fixed `send_failing_checks` for default Rails 5 ActiveJob adapter

## 1.7.3

- Fixed JavaScript errors
- Fixed query cancel error
- Return search results for "me" or "mine"
- Include sample data in email when bad data checks fail
- Fixed deprecation warnings

## 1.7.2

- Cancel all queries on page nav
- Prevent Ace from taking over find command
- Added ability to use hashes for smart columns
- Added ability to inherit smart variables and columns from other data sources

## 1.7.1

- Do not fork when enter key pressed
- Use custom version of Chart.js to fix label overlap
- Improved performance of home page

## 1.7.0

- Added ability to cancel queries on backend for Postgres and Redshift
- Only run 3 queries at a time on dashboards
- Better anomaly detection
- Attempt to reconnect when connection issues
- Fixed issues with caching

## 1.6.2

- Added basic query permissions
- Added ability to use arrays and hashes for smart variables
- Added cancel button for queries
- Added `lat` and `lng` as map keys

## 1.6.1

- Added support for Presto [beta]
- Added support for Elasticsearch timeouts
- Fixed error in Rails 5

## 1.6.0

- Added support for MongoDB [beta]
- Added support for Elasticsearch [beta]
- Fixed deprecation warning in Rails 5

## 1.5.1

- Added anomaly detection for data less than 2 weeks
- Added autolinking urls
- Added support for images

## 1.5.0

- Added new bar chart format
- Added anomaly detection checks
- Added `async` option for polling

## 1.4.0

- Added `slow` cache mode
- Fixed `BLAZER_DATABASE_URL required` error
- Fixed issue with duplicate column names

## 1.3.5

- Fixed error with checks

## 1.3.4

- Fixed issue with missing queries

## 1.3.3

- Fixed error with Rails 4.1 and below

## 1.3.2

- Added support for Rails 5
- Attempt to reconnect for checks

## 1.3.1

- Fixed migration error

## 1.3.0

- Added schedule for checks
- Switched to Chart.js for charts
- Better output for explain
- Support for MySQL timeouts
- Raise error when timeout not supported
- Added creator to dashboards and checks

## 1.2.1

- Fixed checks

## 1.2.0

- Added non-editable queries
- Added variable defaults
- Added `local_time_suffix` setting
- Better timeout message
- Hide variables from commented out lines
- Fixed regex as variable names

## 1.1.1

- Added `before_action` option
- Added invert option for checks
- Added targets
- Friendlier error message for timeouts
- Fixed request URI too large
- Prevent accidental backspace nav on query page

## 1.1.0

- Replaced pie charts with column charts
- Fixed error with datepicker
- Added fork button to edit query page
- Added a notice when editing a query that is part of a dashboard
- Added refresh for dashboards

## 1.0.4

- Added recently viewed queries and dashboards to home page
- Fixed refresh when transform statement is used
- Fixed error when no user model

## 1.0.3

- Added maps
- Added support for Rails 4.0

## 1.0.2

- Fixed error when installing
- Added `schemas` option

## 1.0.1

- Added comments to queries
- Added `cache` option
- Added `user_method` option
- Added `use_transaction` option

## 1.0.0

- Added support for multiple data sources
- Added dashboards
- Added checks
- Added support for Redshift

## 0.0.8

- Easier to edit queries with variables
- Dynamically expand editor height as needed
- No need for spaces in search

## 0.0.7

- Fixed error when no `User` class
- Fixed forking a query with variables
- Set time zone after Rails initializes

## 0.0.6

- Added fork button
- Fixed trending
- Fixed time zones for date select

## 0.0.5

- Added support for Rails 4.2
- Fixed error with `mysql2` adapter
- Added `user_class` option
