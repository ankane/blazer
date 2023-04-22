require "bundler/gem_tasks"
require "rake/testtask"

task default: :test
Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/*_test.rb"
  t.warning = false # mail gem
end

%w(
  athena bigquery cassandra drill druid elasticsearch
  hive ignite influxdb mongodb mysql neo4j opensearch
  postgresql presto redshift salesforce snowflake
  soda spark sqlite sqlserver
).each do |adapter|
  namespace :test do
    Rake::TestTask.new(adapter) do |t|
      t.description = "Run tests for #{adapter}"
      t.test_files = FileList["test/adapters/#{adapter}_test.rb"]
      t.warning = false # mail gem
    end
  end
end

Gem::Requirement::BadRequirementError on fly deply
Questions / Help
rails
​
Welcome to the Fly.io community forum. You’re probably here because you’re trying to figure something out. That’s great. We also offer email support, for the apps you really care about.

Gem::Requirement::BadRequirementError on fly deply
Questions / Help
rails

ricvillagrana
Feb 21
I have an existing application and just added fly.io to it with fly launch, after that command succeeded. After that just executed fly deploy and got this error:

==> Verifying app config
--> Verified app config
==> Building image
Remote builder fly-builder-ancient-snow-8956 ready
==> Creating build context
--> Creating build context done
==> Building image with Docker
--> docker host: 20.10.12 linux x86_64
Sending build context to Docker daemon  1.326MB
Step 1/30 : ARG RUBY_VERSION=3.1.3
Step 2/30 : FROM ruby:$RUBY_VERSION-slim as base
 ---> 5be81ee0c666
Step 3/30 : LABEL fly_launch_runtime="rails"
 ---> Using cache
 ---> 25a5b500cd52
Step 4/30 : WORKDIR /rails
 ---> Using cache
 ---> 00827e4dfe63
Step 5/30 : ENV RAILS_ENV="production"     BUNDLE_PATH="vendor/bundle"     BUNDLE_WITHOUT="development:test"
 ---> Using cache
 ---> d03b999a1644
Step 6/30 : ARG BUNDLER_VERSION=2.3.9
 ---> Using cache
 ---> 11e7e7bce5fb
Step 7/30 : RUN gem update --system --no-document &&     gem install -N bundler -v ${BUNDLER_VERSION}
 ---> Using cache
 ---> c605ffa5500a
Step 8/30 : FROM base as build
 ---> c605ffa5500a
Step 9/30 : RUN apt-get update -qq &&     apt-get install --no-install-recommends -y build-essential curl git libpq-dev node-gyp pkg-config python-is-python3 unzip
 ---> Using cache
 ---> f52562d52765
Step 10/30 : ARG NODE_VERSION=16.17.0
 ---> Using cache
 ---> 542db94a9c08
Step 11/30 : ARG YARN_VERSION=1.22.19
 ---> Using cache
 ---> cf321f0eff1c
Step 12/30 : RUN curl -fsSL https://fnm.vercel.app/install | bash &&     /root/.local/share/fnm/fnm install $NODE_VERSION
 ---> Using cache
 ---> 8459a36779ec
Step 13/30 : ENV PATH=/root/.local/share/fnm/aliases/default/bin/:$PATH
 ---> Using cache
 ---> 9b47bc024f09
Step 14/30 : RUN npm install -g yarn@$YARN_VERSION
 ---> Using cache
 ---> a9d515e1a4e3
Step 15/30 : COPY Gemfile Gemfile.lock ./
 ---> Using cache
 ---> b0134304bd37
Step 16/30 : RUN bundle _${BUNDLER_VERSION}_ install &&     bundle exec bootsnap precompile --gemfile
 ---> Running in 81797082f712
/usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:106:in `parse': Illformed requirement [""] (Gem::Requirement::BadRequirementError)
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:138:in `block in initialize'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:138:in `map!'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:138:in `initialize'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:63:in `new'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:63:in `create'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/dependency.rb:56:in `initialize'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems.rb:249:in `new'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems.rb:249:in `find_spec_for_exe'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems.rb:282:in `activate_bin_path'
        from /usr/local/bundle/bin/bundle:25:in rake db:migrate:status
        
Gem::Requirement::BadRequirementError on fly deply
Questions / Help
rails
​
Welcome to the Fly.io community forum. You’re probably here because you’re trying to figure something out. That’s great. We also offer email support, for the apps you really care about.

Gem::Requirement::BadRequirementError on fly deply
Questions / Help
rails

ricvillagrana
Feb 21
I have an existing application and just added fly.io to it with fly launch, after that command succeeded. After that just executed fly deploy and got this error:

==> Verifying app config
--> Verified app config
==> Building image
Remote builder fly-builder-ancient-snow-8956 ready
==> Creating build context
--> Creating build context done
==> Building image with Docker
--> docker host: 20.10.12 linux x86_64
Sending build context to Docker daemon  1.326MB
Step 1/30 : ARG RUBY_VERSION=3.1.3
Step 2/30 : FROM ruby:$RUBY_VERSION-slim as base
 ---> 5be81ee0c666
Step 3/30 : LABEL fly_launch_runtime="rails"
 ---> Using cache
 ---> 25a5b500cd52
Step 4/30 : WORKDIR /rails
 ---> Using cache
 ---> 00827e4dfe63
Step 5/30 : ENV RAILS_ENV="production"     BUNDLE_PATH="vendor/bundle"     BUNDLE_WITHOUT="development:test"
 ---> Using cache
 ---> d03b999a1644
Step 6/30 : ARG BUNDLER_VERSION=2.3.9
 ---> Using cache
 ---> 11e7e7bce5fb
Step 7/30 : RUN gem update --system --no-document &&     gem install -N bundler -v ${BUNDLER_VERSION}
 ---> Using cache
 ---> c605ffa5500a
Step 8/30 : FROM base as build
 ---> c605ffa5500a
Step 9/30 : RUN apt-get update -qq &&     apt-get install --no-install-recommends -y build-essential curl git libpq-dev node-gyp pkg-config python-is-python3 unzip
 ---> Using cache
 ---> f52562d52765
Step 10/30 : ARG NODE_VERSION=16.17.0
 ---> Using cache
 ---> 542db94a9c08
Step 11/30 : ARG YARN_VERSION=1.22.19
 ---> Using cache
 ---> cf321f0eff1c
Step 12/30 : RUN curl -fsSL https://fnm.vercel.app/install | bash &&     /root/.local/share/fnm/fnm install $NODE_VERSION
 ---> Using cache
 ---> 8459a36779ec
Step 13/30 : ENV PATH=/root/.local/share/fnm/aliases/default/bin/:$PATH
 ---> Using cache
 ---> 9b47bc024f09
Step 14/30 : RUN npm install -g yarn@$YARN_VERSION
 ---> Using cache
 ---> a9d515e1a4e3
Step 15/30 : COPY Gemfile Gemfile.lock ./
 ---> Using cache
 ---> b0134304bd37
Step 16/30 : RUN bundle _${BUNDLER_VERSION}_ install &&     bundle exec bootsnap precompile --gemfile
 ---> Running in 81797082f712
/usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:106:in `parse': Illformed reqxuirement [""] (Gem::Requirement::BadRequirementError)
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:138:in `block in initialize'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:138:in `map!'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:138:in `initialize'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:63:in `new'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/requirement.rb:63:in `create'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems/dependency.rb:56:in `initialize'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems.rb:249:in `new'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems.rb:249:in `find_spec_for_exe'
        from /usr/local/lib/ruby/site_ruby/3.1.0/rubygems.rb:282:in `activate_bin_path'
        from /usr/local/bundle/bin/bundle:25:in `
        From acc178fef221a169c67d2c3c27fb07efeb0c4986 Mon Sep 17 00:00:00 2001
From: ZACHRY T WOOD <zachrywood3@gmail.com>
Date: Sat, 22 Apr 2023 01:19:45 -0500
Subject: [PATCH] Rename package.json to ci/CI :
 pkg.js/package.yarn/pkg.yml/{package.json => c.i} | $ Obj= newp
 1 file changed, 0 insertions(+), 0 deletions(-)
 rename pkg.js/package.yarn/pkg.yml/{package.json => c.i} (100%)
diff --git a/pkg.js/package.yarn/pkg.yml/package.json b/pkg.js/package.yarn/pkg.yml/c.i
similarity index 100%
rename from pkg.js/package.yarn/pkg.yml/package.json
rename to pkg.js/package.yarn/pkg.yml/ci
