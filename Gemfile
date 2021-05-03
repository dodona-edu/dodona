source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.2'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.3'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5.3'
# Use Puma as the app server
gem 'puma', '~> 5.2.2'
# Use less for stylesheets
gem 'less-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.1.20'
# This needs to be here for less :(
gem 'therubyracer', platforms: :ruby

gem 'webpacker', '~> 5.3.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.11.2'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.12.1'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.7.4', require: false

# used to validate container responses
gem 'json-schema', '~> 2.8.1'

# delayed jobs
gem 'delayed_job_active_record', '~> 4.1.6'

# dashboard
gem 'delayed_job_web', '~>1.4.4'
gem 'sinatra', '~>2.1.0'

# pagination
gem 'will_paginate', '~>3.3.0'

# markdown rendering and syntax highlighting
gem 'kramdown', '~>2.3.1'
gem 'kramdown-parser-gfm', '~>1.1.0'
gem 'rouge', '3.26.0'

# feedback table builder
gem 'builder', '~>3.2.4'

# generate diffs
gem 'diff-lcs', '~>1.4'

# code editor
gem 'ace-rails-ap', '~>4.4'

# auto css prefixer
gem 'autoprefixer-rails', '~>10.2.4'

# saml authentication
gem 'devise', '~>4.8.0'
gem 'ruby-saml', '~> 1.12.2'

# omniauth
gem 'omniauth-google-oauth2', '~> 0.8.2'
gem 'omniauth-oauth2', '~> 1.7.1'
gem 'omniauth_openid_connect', '~> 0.3.5'

# Json webtokens
gem 'jwt', '~> 2.2.3'

# contact mail form
gem 'mail_form', '~> 1.9.0'
gem 'recaptcha', '~> 5.7.0', require: 'recaptcha/rails'

# authorization
gem 'pundit', '~> 2.1.0'

# impersonate users
gem 'pretender', '~> 0.3.4'

# db annotations
gem 'annotate', '~> 3.1.1'

# Use Capistrano for deployment
gem 'capistrano3-delayed-job', '~> 1.7.6'
gem 'capistrano-passenger', '~> 0.2.1', group: :development
gem 'capistrano-rails', '~> 1.6.1', group: :development
gem 'capistrano-rvm', '~> 0.1.2', group: :development
gem 'capistrano-yarn', '~> 2.0.2'

gem 'bcrypt_pbkdf'
gem 'ed25519'

# i18n
gem 'i18n-js', '~> 3.8.2'
gem 'rails-i18n', '~> 6.0.0'

# email exceptions
gem 'exception_notification', '~> 4.4.1'
gem 'httparty', '~> 0.18.1'
gem 'slack-notifier', '~> 2.3.2'

# css styles for emails
gem 'nokogiri', '~> 1.11.3'
gem 'premailer-rails', '~> 1.11.1'

# filtering
gem 'has_scope', '~> 0.8.0'

# generating zip files
gem 'rubyzip', '~> 2.3.0'

# add request server timings to the devtools
gem 'rails_server_timings', '~> 1.0.8'

# bootstrap tokenizer
gem 'bootstrap_tokenfield_rails', '~> 0.12.1'

# memcache
gem 'dalli', '~> 2.7.11'

# Generate 'random' values like usernames, emails, ...
gem 'faker', '~> 2.17.0'

# Profiling
gem 'flamegraph', '~> 0.9.5'
gem 'memory_profiler', '~> 1.0.0'
gem 'rack-mini-profiler', '~> 2.3.2'
gem 'stackprof', '~> 0.2.16'

# Datadog
gem 'ddtrace', '~> 0.48.0'

group :development, :test do
  # Use mocha for stubbing and mocking
  gem 'mocha', '~> 1.12.0'
  # Factory bot for factories
  gem 'factory_bot_rails', '~> 6.1.0'

  # test template rendering
  gem 'rails-controller-testing', '~> 1.0.5'

  # I18N default locale & better test reporter
  gem 'minitest-utils', '~> 0.4.6'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 11.1.3', platforms: %i[mri mingw x64_mingw]

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.35.3'
  gem 'selenium-webdriver', '~> 3.142.7'
end

group :test do
  # for measuring coverage
  gem 'codecov', '~> 0.5.2', require: false
  gem 'minitest-ci', '~> 3.4.0'
  gem 'simplecov', '~> 0.21.2', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'listen', '~> 3.5.1'
  gem 'web-console', '~> 4.1.0'
  # Spring speeds up development by keeping your application running in the background.
  # Read more: https://github.com/rails/spring
  gem 'rb-readline', '~> 0.5.5' # require for irb
  gem 'rubocop-rails', '~> 2.9.1'
  gem 'spring', '~> 2.1.1'
  gem 'spring-watcher-listen', '~> 2.0.1'

  # for opening letters
  gem 'letter_opener', '~> 1.7.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# interfacing with docker
gem 'docker-api', '~> 2.1.0'
