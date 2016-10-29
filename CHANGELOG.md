## 1.7.1 [unreleased]

- Do not fork when enter key pressed
- Use custom version of Chart.js to fix label overlap

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
