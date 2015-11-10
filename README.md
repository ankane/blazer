# Blazer

Explore your data with SQL. Easily create charts and dashboards, and share them with your team.

[Try it out](https://blazerme.herokuapp.com)

[![Screenshot](https://blazerme.herokuapp.com/assets/screenshot-18d79092e635b4b220f57ff7a1ecea41.png)](https://blazerme.herokuapp.com)

:tangerine: Battle-tested at [Instacart](https://www.instacart.com/opensource)

**Blazer 1.0 was recently released!** See the [instructions for upgrading](#10).

:envelope: [Subscribe to releases](https://libraries.io/rubygems/blazer)

## Features

- **Multiple data sources** - works with PostgreSQL, MySQL, and Redshift
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
rails g blazer:install
rake db:migrate
```

And mount the dashboard in your `config/routes.rb`:

```ruby
mount Blazer::Engine, at: "blazer"
```

For production, specify your database:

```ruby
ENV["BLAZER_DATABASE_URL"] = "postgres://user:password@hostname:5432/database"
```

Blazer tries to protect against queries which modify data (by running each query in a transaction and rolling it back), but a safer approach is to use a read only user.  [See how to create one](#permissions).

#### Checks (optional)

Be sure to set a host in `config/environments/production.rb` for emails to work.

```ruby
config.action_mailer.default_url_options = {host: "blazerme.herokuapp.com"}
```

Schedule checks to run every hour (with cron, [Heroku Scheduler](https://addons.heroku.com/scheduler), etc).

```sh
rake blazer:run_checks
```

You can also set up failing checks to be sent once a day (or whatever you prefer).

```sh
rake blazer:send_failing_checks
```

## Permissions

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

### Sensitive Data

To protect sensitive info like password hashes and access tokens, use views. Documentation coming soon.

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
authenticate :user, lambda { |user| user.admin? } do
  mount Blazer::Engine, at: "blazer"
end
```

## Queries

### Variables

Create queries with variables.

```sql
SELECT * FROM users WHERE gender = {gender}
```

Use `{start_time}` and `{end_time}` for time ranges. [Example](https://blazerme.herokuapp.com/queries/8-ratings-by-time-range?start_time=1997-10-03T05%3A00%3A00%2B00%3A00&end_time=1997-10-04T04%3A59%3A59%2B00%3A00)

```sql
SELECT * FROM ratings WHERE rated_at >= {start_time} AND rated_at <= {end_time}
```

### Smart Variables

[Example](https://blazerme.herokuapp.com/queries/9-movies-by-genre)

Suppose you have the query:

```sql
SELECT * FROM users WHERE city_id = {city_id}
```

Instead of remembering each city’s id, users can select cities by name.

Add a smart variable with:

```yml
smart_variables:
  city_id: "SELECT id, name FROM cities ORDER BY name ASC"
```

The first column is the value of the variable, and the second column is the label.

### Linked Columns

[Example](https://blazerme.herokuapp.com/queries/4-highest-rated-movies) - title column

Link results to other pages in your apps or around the web. Specify a column name and where it should link to. You can use the value of the result with `{value}`.

```yml
linked_columns:
  user_id: "/admin/users/{value}"
  ip_address: "http://www.infosniper.net/index.php?ip_address={value}"
```

### Smart Columns

[Example](https://blazerme.herokuapp.com/queries/10-users) - occupation_id column

Suppose you have the query:

```sql
SELECT name, city_id FROM users
```

See which city the user belongs to without a join.

```yml
smart_columns:
  city_id: "SELECT id, name FROM cities WHERE id IN {value}"
```

### Caching

Blazer can automatically cache results to improve speed.

```yml
cache: 60 # minutes
```

Of course, you can force a refresh at any time.

## Charts

Blazer will automatically generate charts based on the types of the columns returned in your query.

### Line Chart

There are two ways to generate line charts.

2+ columns - timestamp, numeric(s) - [Example](https://blazerme.herokuapp.com/queries/1-new-ratings-per-week)

```sql
SELECT date_trunc('week', created_at), COUNT(*) FROM users GROUP BY 1
```

3 columns - timestamp, string, numeric - [Example](https://blazerme.herokuapp.com/queries/7-new-ratings-by-gender-per-month)


```sql
SELECT date_trunc('week', created_at), gender, COUNT(*) FROM users GROUP BY 1, 2
```

### Pie Chart

2 columns - string, numeric - [Example](https://blazerme.herokuapp.com/queries/2-top-genres)

```sql
SELECT gender, COUNT(*) FROM users GROUP BY 1
```

### Maps

Columns named `latitude` and `longitude` or `lat` and `lon` - [Example](https://blazerme.herokuapp.com/queries/11-airports-in-pacific-time-zone)

```sql
SELECT name, latitude, longtitude FROM cities
```

To enable, get an access token from [Mapbox](https://www.mapbox.com/) and set `ENV["MAPBOX_ACCESS_TOKEN"]`.

## Dashboards

Create a dashboard with multiple queries. [Example](https://blazerme.herokuapp.com/dashboards/1-movielens)

If the query has a chart, the chart is shown. Otherwise, you’ll see a table.

If any queries have variables, they will show up on the dashboard.

## Checks

Checks give you a centralized place to see the health of your data. [Example](https://blazerme.herokuapp.com/checks)

Create a query to identify bad rows.

```sql
SELECT * FROM ratings WHERE user_id IS NULL /* all ratings should have a user */
```

Then create check with optional emails if you want to be notified. Emails are sent when a check starts failing, and when it starts passing again.

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

### Redshift

Add [activerecord4-redshift-adapter](https://github.com/aamine/activerecord4-redshift-adapter) to your Gemfile and set:

```ruby
ENV["BLAZER_DATABASE_URL"] = "redshift://user:password@hostname:5439/database"
```

## Learn SQL

Have team members who want to learn SQL? Here are a few great, free resources.

- [Khan Academy](https://www.khanacademy.org/computing/computer-programming/sql)
- [Codecademy](https://www.codecademy.com/courses/learn-sql)

## Useful Tools

For an easy way to group by day, week, month, and more with correct time zones, check out [Groupdate](https://github.com/ankane/groupdate.sql).

## Upgrading

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
rake db:migrate
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

# method name for the user model
# user_name: name

# email to send checks from
# from_email: blazer@example.org
```

## TODO

- advanced permissions
- standalone version
- better navigation

## History

View the [changelog](https://github.com/ankane/blazer/blob/master/CHANGELOG.md)

## Thanks

Blazer uses a number of awesome, open source projects.

- [Rails](https://github.com/rails/rails/)
- [jQuery](https://github.com/jquery/jquery)
- [Bootstrap](https://github.com/twbs/bootstrap)
- [Selectize](https://github.com/brianreavis/selectize.js)
- [List.js](https://github.com/javve/list.js)
- [StickyTableHeaders](https://github.com/jmosbech/StickyTableHeaders)
- [Stupid jQuery Table Sort](https://github.com/joequery/Stupid-Table-Plugin)
- [Date Range Picker](https://github.com/dangrossman/bootstrap-daterangepicker)

Created by [ankane](https://github.com/ankane) and [righi](https://github.com/righi)

Demo data from [MovieLens](http://grouplens.org/datasets/movielens/).

## Want to Make Blazer Better?

That’s awesome! Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/blazer/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/blazer/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

Check out the [dev app](https://github.com/ankane/blazer-dev) to get started.
