# Blazer

Create and share SQL queries instantly

[View the demo](https://blazerme.herokuapp.com)

Works with PostgreSQL and MySQL

:tangerine: Battle-tested at [Instacart](https://www.instacart.com)

## Features

- **Secure** - works with your authentication system
- **Variables** - get the same insights for multiple values
- **Linked Columns** - link to other pages in your apps or around the web
- **Smart Columns** - get the data your want without all the joins
- **Smart Variables** - no need to remember IDs
- **Charts & Maps** - a picture is worth a thousand words

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
ENV["BLAZER_DATABASE_URL"]
```

It is **highly, highly recommended** to use a read only user.  Keep reading to see how to create one.

## Permissions

### PostgreSQL

Create a user with read only permissions:

```sql
BEGIN;
CREATE ROLE blazer LOGIN PASSWORD 'secret123';
GRANT CONNECT ON DATABASE database_name TO blazer;
GRANT USAGE ON SCHEMA public TO blazer;
COMMIT;
```

It is **highly, highly recommended** to protect sensitive information with views.  Documentation coming soon.

### MySQL

Create a user with read only permissions:

```sql
GRANT SELECT, SHOW VIEW ON database_name.* TO blazer@’127.0.0.1′ IDENTIFIED BY ‘secret123‘;
FLUSH PRIVILEGES;
```

It is **highly, highly recommended** to protect sensitive information with views.  Documentation coming soon.

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
authenticate :user, lambda{|user| user.admin? } do
  mount Blazer::Engine, at: "blazer"
end
```

## Customization

Change time zone

```ruby
Blazer.time_zone = "Pacific Time (US & Canada)"
```

Turn off audits

```ruby
Blazer.audit = false
```

Customize user name

```ruby
Blazer.user_name = :first_name
```

## TODO

- better readme
- better navigation
- standalone version
- update lock
- warn when database user has write permissions
- advanced permissions
- favorites
- support for multiple data sources

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

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/blazer/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/blazer/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features
