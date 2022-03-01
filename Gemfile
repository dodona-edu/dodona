source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.0.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.2.2'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5.3'
# Use Puma as the app server
gem 'puma', '~> 5.6.2'

# Use dart-sass for stylesheets
gem 'cssbundling-rails', '~> 1.0.0'

# Use jsbundling to bundle javascript in app/javascript with webpack
gem 'jsbundling-rails', '~> 1.0.0'

# Load sprockets ourselves because rails 7 no longer autoloads this
# This is still used for all javascript in app/assets/javascripts
gem 'sprockets-rails', '~> 3.4.2'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.1.20'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.12.1'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.10.3', require: false

# used to validate container responses
gem 'json-schema', '~> 2.8.1'

# delayed jobs
gem 'delayed_job_active_record', '~> 4.1.7'

# dashboard
gem 'delayed_job_web', '~>1.4.4'
gem 'sinatra', '~>2.1.0'

# pagination
gem 'will_paginate', '~>3.3.1'

# markdown rendering and syntax highlighting
gem 'kramdown', '~>2.3.1'
gem 'kramdown-parser-gfm', '~>1.1.0'
gem 'rouge', '3.28.0'

# feedback table builder
gem 'builder', '~>3.2.4'

# generate diffs
gem 'diff-lcs', '~>1.5'

# code editor
gem 'ace-rails-ap', '~>4.4'

# auto css prefixer
gem 'autoprefixer-rails', '~>10.4.2'

# saml authentication
gem 'devise', '~>4.8.1'
gem 'ruby-saml', '~> 1.14.0'

# omniauth
gem 'omniauth-google-oauth2', '~> 0.8.2'
gem 'omniauth-oauth2', '~> 1.7.2'
gem 'omniauth_openid_connect', '~> 0.4.0'

# Json webtokens
gem 'jwt', '~> 2.3.0'

# contact mail form
gem 'hcaptcha', '~> 7.1.0'
gem 'mail_form', '~> 1.9.0'

# authorization
gem 'pundit', '~> 2.2.0'

# impersonate users
gem 'pretender', '~> 0.4.0'

# db annotations
gem 'annotate', '~> 3.2.0'

# Use Capistrano for deployment
gem 'capistrano3-delayed-job', '~> 1.7.6'
gem 'capistrano-passenger', '~> 0.2.1', group: :development
gem 'capistrano-rails', '~> 1.6.1', group: :development
gem 'capistrano-rvm', '~> 0.1.2', group: :development
gem 'capistrano-yarn', '~> 2.0.2'

gem 'bcrypt_pbkdf'
gem 'ed25519'

# i18n
gem 'i18n-js', '~> 3.9.0'
gem 'rails-i18n', '~> 7.0.2'

# email exceptions
gem 'exception_notification', '~> 4.5.0'
gem 'httparty', '~> 0.20.0'
gem 'slack-notifier', '~> 2.4.0'

# css styles for emails
gem 'nokogiri', '~> 1.13.1'
gem 'premailer-rails', '~> 1.11.1'

# filtering
gem 'has_scope', '~> 0.8.0'

# generating zip files
gem 'rubyzip', '~> 2.3.2'

# add request server timings to the devtools
gem 'rails_server_timings', '~> 1.0.8'

# bootstrap tokenizer
gem 'bootstrap_tokenfield_rails', '~> 0.12.1'

# memcache
gem 'dalli', '~> 3.2.0'

# Generate 'random' values like usernames, emails, ...
gem 'faker', '~> 2.19.0'

# Profiling
gem 'flamegraph', '~> 0.9.5'
gem 'memory_profiler', '~> 1.0.0'
gem 'rack-mini-profiler', '~> 2.3.3'
gem 'stackprof', '~> 0.2.17'

# Datadog temporarily fixed by git pull https://github.com/DataDog/dd-trace-rb/pull/1830 switch to 0.55.0 when available
gem 'ddtrace', github: 'kbacha/dd-trace-rb', branch: 'fixes-dalli-server-version'

# Make sure filesystem changes only happen at the end of a transaction
gem 'after_commit_everywhere', '~> 1.1.0'

# Set io-wait fixed to version 0.2.0 as 0.2.1 is not available in production environment
gem 'io-wait', '~> 0.2.0'

group :development, :test do
  # Use mocha for stubbing and mocking
  gem 'mocha', '~> 1.13.0'
  # Factory bot for factories
  gem 'factory_bot_rails', '~> 6.2.0'

  # test template rendering
  gem 'rails-controller-testing', '~> 1.0.5'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 11.1.3', platforms: %i[mri mingw x64_mingw]

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.36.0'
  gem 'selenium-webdriver', '~> 4.1.0'
end

group :test do
  # For measuring coverage
  gem 'codecov', '~> 0.6.0', require: false
  gem 'minitest-ci', '~> 3.4.0'
  gem 'simplecov', '~> 0.21.2', require: false
  gem 'test-prof', '~> 1.0.7'

  # Mocking HTTP requests to third parties.
  gem 'webmock'

  # I18N default locale & better test reporter
  gem 'minitest-utils', '~> 0.4.8'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'listen', '~> 3.7.1'
  gem 'web-console', '~> 4.2.0'

  gem 'rb-readline', '~> 0.5.5' # require for irb
  gem 'rubocop-rails', '~> 2.13.2'

  # for opening letters
  gem 'letter_opener', '~> 1.7.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# interfacing with docker
gem 'docker-api', '~> 2.2.0'

# Used for syncing deadlines with an external calendar
gem 'icalendar', '~> 2.7'
