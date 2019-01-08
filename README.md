# Blazer

Explore your data with SQL. Easily create charts and dashboards, and share them with your team.

[Try it out](https://blazer.dokkuapp.com)

[![Screenshot](https://blazer.dokkuapp.com/assets/screenshot-6ca3115a518b488026e48be83ba0d4c9.png)](https://blazer.dokkuapp.com)

Blazer 2.0 was recently released! See [instructions for upgrading](#20).

:tangerine: Battle-tested at [Instacart](https://www.instacart.com/opensource)

## Features

- **Multiple data sources** - PostgreSQL, MySQL, Redshift, and [many more](#full-list)
- **Variables** - run the same queries with different values
- **Checks & alerts** - get emailed when bad data appears
- **Audits** - all queries are tracked
- **Security** - works with your authentication system

## Docs

- [Installation](#installation)
- [Queries](#queries)
- [Charts](#charts)
- [Dashboards](#dashboards)
- [Checks](#checks)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'blazer'
```

Run:

```sh
rails generate blazer:install
rails db:migrate
```

And mount the dashboard in your `config/routes.rb`:

```ruby
mount Blazer::Engine, at: "blazer"
```

For production, specify your database:

```ruby
ENV["BLAZER_DATABASE_URL"] = "postgres://user:password@hostname:5432/database"
```

Blazer tries to protect against queries which modify data (by running each query in a transaction and rolling it back), but a safer approach is to use a read only user. [See how to create one](#permissions).

#### Checks (optional)

Be sure to set a host in `config/environments/production.rb` for emails to work.

```ruby
config.action_mailer.default_url_options = {host: "blazer.dokkuapp.com"}
```

Schedule checks to run (with cron, [Heroku Scheduler](https://elements.heroku.com/addons/scheduler), etc). The default options are every 5 minutes, 1 hour, or 1 day, which you can customize. For each of these options, set up a task to run.

```sh
rake blazer:run_checks SCHEDULE="5 minutes"
rake blazer:run_checks SCHEDULE="1 hour"
rake blazer:run_checks SCHEDULE="1 day"
```

You can also set up failing checks to be sent once a day (or whatever you prefer).

```sh
rake blazer:send_failing_checks
```

Here’s what it looks like with cron.

```
*/5 * * * * rake blazer:run_checks SCHEDULE="5 minutes"
0   * * * * rake blazer:run_checks SCHEDULE="1 hour"
30  7 * * * rake blazer:run_checks SCHEDULE="1 day"
0   8 * * * rake blazer:send_failing_checks
```

For Slack notifications, create an [incoming webhook](https://slack.com/apps/A0F7XDUAZ-incoming-webhooks) and set:

```sh
BLAZER_SLACK_WEBHOOK_URL=https://hooks.slack.com/...
```

Name the webhook “Blazer” and add a cool icon.

## Authentication

Don’t forget to protect the dashboard in production.

### Basic Authentication

Set the following variables in your environment or an initializer.

```ruby
ENV["BLAZER_USERNAME"] = "andrew"
ENV["BLAZER_PASSWORD"] = "secret"
```

### Devise

```ruby
authenticate :user, ->(user) { user.admin? } do
  mount Blazer::Engine, at: "blazer"
end
```

### Other

Specify a `before_action` method to run in `blazer.yml`.

```yml
before_action_method: require_admin
```

You can define this method in your `ApplicationController`.

```ruby
def require_admin
  # depending on your auth, something like...
  redirect_to root_path unless current_user && current_user.admin?
end
```

Be sure to render or redirect for unauthorized users.

## Permissions

Blazer runs each query in a transaction and rolls it back to prevent queries from modifying data. As an additional line of defense, we recommend using a read only user.

### PostgreSQL

Create a user with read only permissions:

```sql
BEGIN;
CREATE ROLE blazer LOGIN PASSWORD 'secret123';
GRANT CONNECT ON DATABASE database_name TO blazer;
GRANT USAGE ON SCHEMA public TO blazer;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO blazer;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO blazer;
COMMIT;
```

### MySQL

Create a user with read only permissions:

```sql
GRANT SELECT, SHOW VIEW ON database_name.* TO blazer@’127.0.0.1′ IDENTIFIED BY ‘secret123‘;
FLUSH PRIVILEGES;
```

### MongoDB

Create a user with read only permissions:

```
db.createUser({user: "blazer", pwd: "password", roles: ["read"]})
```

Also, make sure authorization is enabled when you start the server.

## Sensitive Data

If your database contains sensitive or personal data, check out [Hypershield](https://github.com/ankane/hypershield) to shield it.

## Queries

### Variables

Create queries with variables.

```sql
SELECT * FROM users WHERE gender = {gender}
```

Use `{start_time}` and `{end_time}` for time ranges. [Example](https://blazer.dokkuapp.com/queries/9-time-range-selector?start_time=1997-10-03T05%3A00%3A00%2B00%3A00&end_time=1997-10-04T04%3A59%3A59%2B00%3A00)

```sql
SELECT * FROM ratings WHERE rated_at >= {start_time} AND rated_at <= {end_time}
```

### Smart Variables

[Example](https://blazer.dokkuapp.com/queries/1-smart-variable)

Suppose you have the query:

```sql
SELECT * FROM users WHERE occupation_id = {occupation_id}
```

Instead of remembering each occupation’s id, users can select occupations by name.

Add a smart variable with:

```yml
smart_variables:
  occupation_id: "SELECT id, name FROM occupations ORDER BY name ASC"
```

The first column is the value of the variable, and the second column is the label.

You can also use an array or hash for static data and enums.

```yml
smart_variables:
  period: ["day", "week", "month"]
  status: {0: "Active", 1: "Archived"}
```

### Linked Columns

[Example](https://blazer.dokkuapp.com/queries/3-linked-column) - title column

Link results to other pages in your apps or around the web. Specify a column name and where it should link to. You can use the value of the result with `{value}`.

```yml
linked_columns:
  user_id: "/admin/users/{value}"
  ip_address: "https://www.infosniper.net/index.php?ip_address={value}"
```

### Smart Columns

[Example](https://blazer.dokkuapp.com/queries/2-smart-column) - occupation_id column

Suppose you have the query:

```sql
SELECT name, city_id FROM users
```

See which city the user belongs to without a join.

```yml
smart_columns:
  city_id: "SELECT id, name FROM cities WHERE id IN {value}"
```

You can also use a hash for static data and enums.

```yml
smart_columns:
  status: {0: "Active", 1: "Archived"}
```

### Caching

Blazer can automatically cache results to improve speed. It can cache slow queries:

```yml
cache:
  mode: slow
  expires_in: 60 # min
  slow_threshold: 15 # sec
```

Or it can cache all queries:

```yml
cache:
  mode: all
  expires_in: 60 # min
```

Of course, you can force a refresh at any time.

## Charts

Blazer will automatically generate charts based on the types of the columns returned in your query.

**Note:** The order of columns matters.

### Line Chart

There are two ways to generate line charts.

2+ columns - timestamp, numeric(s) - [Example](https://blazer.dokkuapp.com/queries/4-line-chart-format-1)

```sql
SELECT date_trunc('week', created_at), COUNT(*) FROM users GROUP BY 1
```

3 columns - timestamp, string, numeric - [Example](https://blazer.dokkuapp.com/queries/5-line-chart-format-2)


```sql
SELECT date_trunc('week', created_at), gender, COUNT(*) FROM users GROUP BY 1, 2
```

### Column Chart

There are also two ways to generate column charts.

2+ columns - string, numeric(s) - [Example](https://blazer.dokkuapp.com/queries/6-column-chart-format-1)

```sql
SELECT gender, COUNT(*) FROM users GROUP BY 1
```

3 columns - string, string, numeric - [Example](https://blazer.dokkuapp.com/queries/7-column-chart-format-2)

```sql
SELECT gender, zip_code, COUNT(*) FROM users GROUP BY 1, 2
```

### Scatter Chart

2 columns - both numeric - [Example](https://blazer.dokkuapp.com/queries/16-scatter-chart)

```sql
SELECT x, y FROM table
```

### Pie Chart

2 columns - string, numeric - and last column named `pie` - [Example](https://blazer.dokkuapp.com/queries/17-pie-chart)

```sql
SELECT gender, COUNT(*) AS pie FROM users GROUP BY 1
```

### Maps

Columns named `latitude` and `longitude` or `lat` and `lon` or `lat` and `lng` - [Example](https://blazer.dokkuapp.com/queries/15-map)

```sql
SELECT name, latitude, longitude FROM cities
```

To enable, get an access token from [Mapbox](https://www.mapbox.com/) and set `ENV["MAPBOX_ACCESS_TOKEN"]`.

### Targets

Use the column name `target` to draw a line for goals. [Example](https://blazer.dokkuapp.com/queries/8-target-line)

```sql
SELECT date_trunc('week', created_at), COUNT(*) AS new_users, 100000 AS target FROM users GROUP BY 1
```

## Dashboards

Create a dashboard with multiple queries. [Example](https://blazer.dokkuapp.com/dashboards/1-dashboard-demo)

If the query has a chart, the chart is shown. Otherwise, you’ll see a table.

If any queries have variables, they will show up on the dashboard.

## Checks

Checks give you a centralized place to see the health of your data. [Example](https://blazer.dokkuapp.com/checks)

Create a query to identify bad rows.

```sql
SELECT * FROM ratings WHERE user_id IS NULL /* all ratings should have a user */
```

Then create check with optional emails if you want to be notified. Emails are sent when a check starts failing, and when it starts passing again.

## Anomaly Detection

Blazer supports two different approaches to anomaly detection.

### Trend

[Trend](https://trendapi.org/) is easiest to set up but uses an external service.

Add [trend](https://github.com/ankane/trend) to your Gemfile:

```ruby
gem 'trend'
```

And add to `config/blazer.yml`:

```yml
anomaly_checks: trend
```

### R

R is harder to set up but doesn’t use an external service. It uses Twitter’s [AnomalyDetection](https://github.com/twitter/AnomalyDetection) library.

First, [install R](https://cloud.r-project.org/). Then, run:

```R
install.packages("remotes")
remotes::install_github("twitter/AnomalyDetection")
```

And add to `config/blazer.yml`:

```yml
anomaly_checks: r
```

If upgrading from version 1.4 or below, also follow the [upgrade instructions](#15).

If you’re on Heroku, follow [these additional instructions](#anomaly-detection-on-heroku).

## Forecasting

Blazer has experimental support for forecasting through [Trend](https://trendapi.org/).

[Example](https://blazer.dokkuapp.com/queries/18-forecast?forecast=t)

Add [trend](https://github.com/ankane/trend) to your Gemfile:

```ruby
gem 'trend'
```

And add to `config/blazer.yml`:

```yml
forecasting: trend
```

A forecast link will appear for queries that return 2 columns with types timestamp and numeric.

## Data Sources

Blazer supports multiple data sources :tada:

Add additional data sources in `config/blazer.yml`:

```yml
data_sources:
  main:
    url: <%= ENV["BLAZER_DATABASE_URL"] %>
    # timeout, smart_variables, linked_columns, smart_columns
  catalog:
    url: <%= ENV["CATALOG_DATABASE_URL"] %>
    # ...
  redshift:
    url: <%= ENV["REDSHIFT_DATABASE_URL"] %>
    # ...
```

### Full List

- [Amazon Athena](#amazon-athena)
- [Amazon Redshift](#amazon-redshift)
- [Apache Drill](#apache-drill)
- [Cassandra](#cassandra)
- [Druid](#druid)
- [Elasticsearch](#elasticsearch)
- [Google BigQuery](#google-bigquery)
- [IBM DB2 and Informix](#ibm-db2-and-informix)
- [MongoDB](#mongodb-1)
- [MySQL](#mysql-1)
- [Oracle](#oracle)
- [PostgreSQL](#postgresql-1)
- [Presto](#presto)
- [Snowflake](#snowflake)
- [SQLite](#sqlite)
- [SQL Server](#sql-server)

You can also [create an adapter](#creating-an-adapter) for any other data store.

**Note:** In the examples below, we recommend using environment variables for urls.

```yml
data_sources:
  my_source:
    url: <%= ENV["BLAZER_MY_SOURCE_URL"] %>
```

### Amazon Athena

Add [aws-sdk-athena](https://github.com/aws/aws-sdk-ruby) and [aws-sdk-glue](https://github.com/aws/aws-sdk-ruby) to your Gemfile and set:

```yml
data_sources:
  my_source:
    adapter: athena
    database: database
    output_location: s3://some-bucket/
```

### Amazon Redshift

Add [activerecord4-redshift-adapter](https://github.com/aamine/activerecord4-redshift-adapter) or [activerecord5-redshift-adapter](https://github.com/ConsultingMD/activerecord5-redshift-adapter) to your Gemfile and set:

```yml
data_sources:
  my_source:
    url: redshift://user:password@hostname:5439/database
```

### Apache Drill

Add [drill-sergeant](https://github.com/ankane/drill-sergeant) to your Gemfile and set:

```yml
data_sources:
  my_source:
    adapter: drill
    url: http://hostname:8047
```

### Cassandra

Add [cassandra-driver](https://github.com/datastax/ruby-driver) to your Gemfile and set:

```yml
data_sources:
  my_source:
    url: cassandra://user:password@hostname:9042/keyspace
```

### Druid

First, [enable SQL support](http://druid.io/docs/latest/querying/sql.html#configuration) on the broker.

Set:

```yml
data_sources:
  my_source:
    adapter: druid
    url: http://hostname:8082
```

### Elasticsearch

Add [elasticsearch](https://github.com/elastic/elasticsearch-ruby) and [elasticsearch-xpack](https://github.com/elastic/elasticsearch-ruby/tree/master/elasticsearch-xpack) to your Gemfile and set:

```yml
data_sources:
  my_source:
    adapter: elasticsearch
    url: http://user:password@hostname:9200
```

### Google BigQuery

Add [google-cloud-bigquery](https://github.com/GoogleCloudPlatform/google-cloud-ruby/tree/master/google-cloud-bigquery) to your Gemfile and set:

```yml
data_sources:
  my_source:
    adapter: bigquery
    project: your-project
    keyfile: path/to/keyfile.json
```

### IBM DB2 and Informix

Use [ibm_db](https://github.com/ibmdb/ruby-ibmdb).

### MongoDB

Add [mongo](https://github.com/mongodb/mongo-ruby-driver) to your Gemfile and set:

```yml
data_sources:
  my_source:
    url: mongodb://user:password@hostname:27017/database
```

### MySQL

Add [mysql2](https://github.com/brianmario/mysql2) to your Gemfile (if it’s not there) and set:

```yml
data_sources:
  my_source:
    url: mysql2://user:password@hostname:3306/database
```

### Oracle

Use [activerecord-oracle_enhanced-adapter](https://github.com/rsim/oracle-enhanced).

### PostgreSQL

Add [pg](https://bitbucket.org/ged/ruby-pg/wiki/Home) to your Gemfile (if it’s not there) and set:

```yml
data_sources:
  my_source:
    url: postgres://user:password@hostname:5432/database
```

### Presto

Add [presto-client](https://github.com/treasure-data/presto-client-ruby) to your Gemfile and set:

```yml
data_sources:
  my_source:
    url: presto://user@hostname:8080/catalog
```

### Snowflake

First, install the [ODBC driver](https://docs.snowflake.net/manuals/user-guide/odbc.html). Add [odbc_adapter](https://github.com/localytics/odbc_adapter) to your Gemfile and set:

```yml
data_sources:
  my_source:
    adapter: snowflake
    dsn: ProductionSnowflake
```

### SQLite

Add [sqlite3](https://github.com/sparklemotion/sqlite3-ruby) to your Gemfile and set:

```yml
data_sources:
  my_source:
    url: sqlite3:path/to/database.sqlite3
```

### SQL Server

Add [tiny_tds](https://github.com/rails-sqlserver/tiny_tds) and [activerecord-sqlserver-adapter](https://github.com/rails-sqlserver/activerecord-sqlserver-adapter) to your Gemfile and set:

```yml
data_sources:
  my_source:
    url: sqlserver://user:password@hostname:1433/database
```

## Creating an Adapter

Create an adapter for any data store with:

```ruby
class FooAdapter < Blazer::Adapters::BaseAdapter
  # code goes here
end

Blazer.register_adapter "foo", FooAdapter
```

See the [Presto adapter](https://github.com/ankane/blazer/blob/master/lib/blazer/adapters/presto_adapter.rb) for a good example. Then use:

```yml
data_sources:
  my_source:
    adapter: foo
    url: http://user:password@hostname:9200/
```

## Query Permissions

Blazer supports a basic permissions model.

1. Queries without a name are unlisted
2. Queries whose name starts with `#` are only listed to the creator
3. Queries whose name starts with `*` can only be edited by the creator

## Learn SQL

Have team members who want to learn SQL? Here are a few great, free resources.

- [Khan Academy](https://www.khanacademy.org/computing/computer-programming/sql)
- [Codecademy](https://www.codecademy.com/learn/learn-sql)

## Useful Tools

For an easy way to group by day, week, month, and more with correct time zones, check out [Groupdate](https://github.com/ankane/groupdate.sql).

## Standalone Version

Looking for a standalone version? Check out [Ghost Blazer](https://github.com/buren/ghost_blazer).

## Performance

By default, queries take up a request while they are running. To run queries asynchronously, add to your config:

```yml
async: true
```

**Note:** Requires Rails 5+ and caching to be enabled. If you have multiple web processes, your app must use a centralized cache store like Memcached or Redis.

```ruby
config.cache_store = :mem_cache_store
```

## Anomaly Detection on Heroku

Add the [R buildpack](https://github.com/virtualstaticvoid/heroku-buildpack-r) to your app.

```sh
heroku buildpacks:add --index 1 https://github.com/virtualstaticvoid/heroku-buildpack-r.git\#cedar-14
```

And create an `init.r` with:

```sh
if (!"AnomalyDetection" %in% installed.packages()) {
  install.packages("devtools")
  devtools::install_github("twitter/AnomalyDetection")
}
```

Commit and deploy away. The first deploy may take a few minutes.

## Content Security Policy

If views are stuck with a `Loading...` message, there might be a problem with strict CSP settings in your app. This can be checked with Firefox or Chrome dev tools. You can allow Blazer to override these settings for its controllers with:

```yml
override_csp: true
```

## Upgrading

### 2.0

To use Slack notifications, create a migration

```sh
rails g migration add_slack_channels_to_blazer_checks
```

with:

```ruby
add_column :blazer_checks, :slack_channels, :text
```

### 1.5

To take advantage of the anomaly detection, create a migration

```sh
rails g migration upgrade_blazer_to_1_5
```

with:

```ruby
add_column :blazer_checks, :check_type, :string
add_column :blazer_checks, :message, :text
commit_db_transaction

Blazer::Check.reset_column_information

Blazer::Check.where(invert: true).update_all(check_type: "missing_data")
Blazer::Check.where(check_type: nil).update_all(check_type: "bad_data")
```

### 1.3

To take advantage of the latest features, create a migration

```sh
rails g migration upgrade_blazer_to_1_3
```

with:

```ruby
add_column :blazer_dashboards, :creator_id, :integer
add_column :blazer_checks, :creator_id, :integer
add_column :blazer_checks, :invert, :boolean
add_column :blazer_checks, :schedule, :string
add_column :blazer_checks, :last_run_at, :timestamp
commit_db_transaction

Blazer::Check.update_all schedule: "1 hour"
```

### 1.0

Blazer 1.0 brings a number of new features:

- multiple data sources, including Redshift
- dashboards
- checks

To upgrade, run:

```sh
bundle update blazer
```

Create a migration

```sh
rails g migration upgrade_blazer_to_1_0
```

with:

```ruby
add_column :blazer_queries, :data_source, :string
add_column :blazer_audits, :data_source, :string

create_table :blazer_dashboards do |t|
  t.text :name
  t.timestamps
end

create_table :blazer_dashboard_queries do |t|
  t.references :dashboard
  t.references :query
  t.integer :position
  t.timestamps
end

create_table :blazer_checks do |t|
  t.references :query
  t.string :state
  t.text :emails
  t.timestamps
end
```

And run:

```sh
rails db:migrate
```

Update `config/blazer.yml` with:

```yml
# see https://github.com/ankane/blazer for more info

data_sources:
  main:
    url: <%= ENV["BLAZER_DATABASE_URL"] %>

    # statement timeout, in seconds
    # applies to PostgreSQL only
    # none by default
    # timeout: 15

    # time to cache results, in minutes
    # can greatly improve speed
    # none by default
    # cache: 60

    # wrap queries in a transaction for safety
    # not necessary if you use a read-only user
    # true by default
    # use_transaction: false

    smart_variables:
      # zone_id: "SELECT id, name FROM zones ORDER BY name ASC"

    linked_columns:
      # user_id: "/admin/users/{value}"

    smart_columns:
      # user_id: "SELECT id, name FROM users WHERE id IN {value}"

# create audits
audit: true

# change the time zone
# time_zone: "Pacific Time (US & Canada)"

# class name of the user model
# user_class: User

# method name for the current user
# user_method: current_user

# method name for the display name
# user_name: name

# email to send checks from
# from_email: blazer@example.org
```

## History

View the [changelog](https://github.com/ankane/blazer/blob/master/CHANGELOG.md)

## Thanks

Blazer uses a number of awesome open source projects, including [Rails](https://github.com/rails/rails/), [Vue.js](https://github.com/vuejs/vue), [jQuery](https://github.com/jquery/jquery), [Bootstrap](https://github.com/twbs/bootstrap), [Selectize](https://github.com/brianreavis/selectize.js), [StickyTableHeaders](https://github.com/jmosbech/StickyTableHeaders), [Stupid jQuery Table Sort](https://github.com/joequery/Stupid-Table-Plugin), and [Date Range Picker](https://github.com/dangrossman/bootstrap-daterangepicker).

Demo data from [MovieLens](https://grouplens.org/datasets/movielens/).

## Want to Make Blazer Better?

That’s awesome! Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/blazer/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/blazer/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

Check out the [dev app](https://github.com/ankane/blazer-dev) to get started.
