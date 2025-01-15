source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.3.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 8.0.1'
# Use trilogy to interact with mysql as the database for Active Record
gem 'trilogy', '~> 2.9.0'
# Use Puma as the app server
gem 'puma', '~> 6.5.0'

# Use dart-sass for stylesheets
gem 'cssbundling-rails', '~> 1.4.1'

# Use jsbundling to bundle javascript in app/javascript with webpack
gem 'jsbundling-rails', '~> 1.3.1'

# Load sprockets ourselves because rails 7 no longer autoloads this
# This is still used for all javascript in app/assets/javascripts
gem 'sprockets-rails', '~> 3.5.2'

# Use Terser as compressor for JavaScript assets
# gem 'terser', '>= 1.1.1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.13.0'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.13.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.18.4', require: false

# used to validate container responses
gem 'json_schemer', '~> 2.3.0'

# delayed jobs
gem 'delayed_job_active_record', '~> 4.1.11'

# dashboard
gem 'delayed_job_web', '~>1.4.4'

# pagination
gem 'will_paginate', '~>4.0.1'

# markdown rendering and syntax highlighting
gem 'kramdown', '~>2.5.1'
gem 'kramdown-parser-gfm', '~>1.1.0'
gem 'rouge', '4.5.1'

# feedback table builder
gem 'builder', '~>3.3.0'

# generate diffs
gem 'diff-lcs', '~>1.5'

# auto css prefixer
gem 'autoprefixer-rails', '~>10.4.19'

# saml authentication
gem 'devise', '~>4.9.4'
gem 'ruby-saml', '~> 1.17.0'

# omniauth
gem 'omniauth-google-oauth2', '~> 1.2.0'
gem 'omniauth-oauth2', '~> 1.8.0'
gem 'omniauth_openid_connect', '~> 0.8.0'
gem 'omniauth-rails_csrf_protection', '~> 1.0.2'

# Json webtokens
gem 'jwt', '~> 2.10.1'

# contact mail form
gem 'hcaptcha', '~> 7.1.0'
gem 'mail_form', '~> 1.10.1'

# authorization
gem 'pundit', '~> 2.4.0'

# impersonate users
gem 'pretender', '~> 0.5.0'

# db annotations
gem 'annotaterb', '~> 4.13.0'

# Use Capistrano for deployment
gem 'capistrano3-delayed-job', '~> 1.7.6'
gem 'capistrano-passenger', '~> 0.2.1', group: :development
gem 'capistrano-rails', '~> 1.7.0', group: :development
gem 'capistrano-rvm', '~> 0.1.2', group: :development
gem 'capistrano-yarn', '~> 2.0.2'

gem 'bcrypt_pbkdf'
gem 'ed25519'

# i18n
gem 'i18n-js', '~> 4.2.3'
gem 'rails-i18n', '~> 8.0.1'

# email exceptions
gem "exception_notification", git: "https://github.com/smartinez87/exception_notification.git", branch: "master" # following master until fix is released for https://github.com/smartinez87/exception_notification/issues/545
gem 'httparty', '~> 0.22.0'
gem 'slack-notifier', '~> 2.4.0'

# css styles for emails
gem 'css_parser', '~> 1.21.0' # dependency for premailer, set to higher version for ruby 3.3 support
gem 'nokogiri', '~> 1.18.1'
gem 'premailer-rails', '~> 1.12.0'

# filtering
gem 'has_scope', '~> 0.8.2'

# generating zip files
gem 'rubyzip', '~> 2.4.1'

# memcache
gem 'dalli', '~> 3.2.8'

# Generate 'random' values like usernames, emails, ...
gem 'faker', '~> 3.5.1'

# Profiling
gem 'flamegraph', '~> 0.9.5'
gem 'memory_profiler', '~> 1.1.0'
gem 'rack-mini-profiler', '~> 3.3.1'
gem 'stackprof', '~> 0.2.26'

gem 'datadog', '~> 2.8.0'

# Make sure filesystem changes only happen at the end of a transaction
gem 'after_commit_everywhere', '~> 1.5.0'

# More advanced counter_cache that allows conditions
gem 'counter_culture', '~> 3.8'

group :development, :test do
  # Use mocha for stubbing and mocking
  gem 'mocha', '~> 2.7.1'
  # Factory bot for factories
  gem 'factory_bot_rails', '~> 6.4.4'

  # test template rendering
  gem 'rails-controller-testing', '~> 1.0.5'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 11.1.3', platforms: %i[mri mingw x64_mingw]

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.40.0'
  gem 'selenium-webdriver', '~> 4.27.0'
end

group :test do
  # For measuring coverage
  gem 'minitest-ci', '~> 3.4.0'
  gem 'simplecov', '~> 0.22.0', require: false
  gem 'simplecov-cobertura', '~> 2.1.0', require: false
  gem 'test-prof', '~> 1.4.4'

  # Mocking HTTP requests to third parties.
  gem 'webmock'

  # I18N default locale & better test reporter
  gem 'minitest-utils', '~> 0.4.8'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'listen', '~> 3.9.0'
  gem 'web-console', '~> 4.2.1'

  gem 'rb-readline', '~> 0.5.5' # require for irb
  gem 'rubocop-capybara', '~> 2.21.0'
  gem 'rubocop-factory_bot', '~> 2.26'
  gem 'rubocop-minitest', '~> 0.36.0'
  gem 'rubocop-rails', '~> 2.28.0'

  # for opening letters
  gem 'letter_opener', '~> 1.10.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# interfacing with docker
gem 'docker-api', '~> 2.4.0'

# Used for syncing deadlines with an external calendar
gem 'icalendar', '~> 2.10'
