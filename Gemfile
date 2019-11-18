source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.1'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5.2'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use less for stylesheets
gem 'less-rails', '~> 4.0'
# less-rails does not support sprockets 4.0
gem 'sprockets', '< 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.1.20'
# This needs to be here for less :(
gem 'therubyracer', platforms: :ruby

gem 'webpacker', '~> 4.0.7'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.9.1'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
gem 'image_processing', '~> 1.9.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.4.5', require: false

# used to validate container responses
gem 'json-schema', '~> 2.8.1'

# delayed jobs
gem 'delayed_job_active_record', '~> 4.1.4'

# start workers in the background
gem 'daemons', '~>1.3'

# dashboard
gem 'delayed_job_web', '~>1.4.3'
gem 'sinatra', '~>2.0.7'

# pagination
gem 'will_paginate', '~>3.2.1'

# markdown rendering and syntax highlighting
gem 'kramdown', '~>2.1.0'
gem 'kramdown-parser-gfm', '~>1.1.0'
gem 'rouge', '3.12.0'

# feedback table builder
gem 'builder', '~>3.2.3'

# generate diffs
gem 'diff-lcs', '~>1.3'

# code editor
gem 'ace-rails-ap', '~>4.2'

# auto css prefixer
gem 'autoprefixer-rails', '~>9.7.1'

# saml authentication
gem 'devise', '~>4.7.1'
gem 'devise_saml_authenticatable', '~> 1.5.0'

# omniauth
gem 'omniauth-google-oauth2', '~> 0.8.0'
gem 'omniauth-oauth2', '~> 1.6.0'

gem 'jwt', '~> 2.2.1'

# contact mail form
gem 'mail_form', '~> 1.8.0'
gem 'recaptcha', '~> 5.2.1', require: 'recaptcha/rails'

# authorization
gem 'pundit', '~> 2.1.0'

# impersonate users
gem 'pretender', '~> 0.3.4'

# db annotations
gem 'annotate', '~> 3.0.3'

# Use Capistrano for deployment
gem 'capistrano-passenger', '~> 0.2.0', group: :development
gem 'capistrano-rails', '~> 1.4.0', group: :development
gem 'capistrano-rvm', '~> 0.1.2', group: :development
gem 'capistrano-yarn', '~> 2.0.2'
gem 'capistrano3-delayed-job', '~> 1.7.6'

gem 'bcrypt_pbkdf'
gem 'ed25519'

# i18n
gem 'i18n-js', '~> 3.4.2'
gem 'rails-i18n', '~> 6.0.0'

# email exceptions
gem 'exception_notification', '~> 4.4.0'
gem 'httparty', '~> 0.17.1'
gem 'slack-notifier', '~> 2.3.2'

# css styles for emails
gem 'nokogiri', '~> 1.10.5'
gem 'premailer-rails', '~> 1.10.3'

# filtering
gem 'has_scope', '~> 0.7.2'

# generating zip files
gem 'rubyzip', '~> 2.0.0'

# add request server timings to the devtools
gem 'rails_server_timings', '~> 1.0.8'

# Maybe in Ruby
gem 'possibly', '~> 1.0.1'

# bootstrap tokenizer
gem 'bootstrap_tokenfield_rails', '~> 0.12.1'

# memcache
gem 'dalli', '~> 2.7.10'

# Generate 'random' values like usernames, emails, ...
gem 'faker', '~> 2.7.0'

group :development, :test do
  # Use mocha for stubbing and mocking
  gem 'mocha', '~> 1.9.0'
  # Factory bot for factories
  gem 'factory_bot_rails', '~> 5.1.1'

  # test template rendering
  gem 'rails-controller-testing', '~> 1.0.4'

  # I18N default locale & better test reporter
  gem 'minitest-utils', '~> 0.4.4'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 11.0.1', platforms: %i[mri mingw x64_mingw]

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 3.29.0'
  gem 'selenium-webdriver', '~> 3.142.6'
end

group :test do
  # for measuring coverage
  gem 'codecov', '~> 0.1.16', require: false
  gem 'minitest-ci', '~> 3.4.0'
  gem 'simplecov', '~> 0.17.1', require: false
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'listen', '~> 3.2.0'
  gem 'web-console', '~> 4.0.1'
  # Spring speeds up development by keeping your application running in the background.
  # Read more: https://github.com/rails/spring
  gem 'rb-readline', '~> 0.5.5' # require for irb
  gem 'rubocop-rails', '~> 2.3.2'
  gem 'spring', '~> 2.1.0'
  gem 'spring-watcher-listen', '~> 2.0.1'

  # Manage processes (webpack, rails, delayed_job, ...)
  gem 'foreman', github: 'andrewmcodes/foreman'

  # for opening letters
  gem 'letter_opener', '~> 1.7.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# interfacing with docker
gem 'docker-api', '~> 1.34.2'
