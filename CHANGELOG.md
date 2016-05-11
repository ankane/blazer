## 1.3.4 [unreleased]

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
