source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.2', '>= 5.2.2.1'
# Use mysql as the database for Active Record
gem 'mysql2', '~> 0.5.2'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'less-rails', '~> 3.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 4.1.18'
# This needs to be here for less :(
gem 'therubyracer', platforms: :ruby
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'

gem 'webpacker', '~> 3.5.5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# used to validate container responses
gem 'json-schema'

# delayed jobs
gem 'delayed_job_active_record'
# start workers in the background
gem 'daemons'
# dashboard
github 'sinatra/sinatra' do
  gem 'rack-protection'
  gem 'sinatra'
end
gem 'delayed_job_web'

# pagination
gem 'will_paginate'

# markdown rendering and syntax highlighting
gem 'kramdown'
gem 'rouge', '1.10.1'

# feedback table builder
gem 'builder'

# generate diffs
gem 'diff-lcs'

# code editor
gem 'ace-rails-ap'

# auto css prefixer
gem 'autoprefixer-rails'

# saml authentication
gem 'devise'
gem 'devise_saml_authenticatable', '~> 1.5.0'

# omniauth
gem 'omniauth-oauth2', '~> 1.6.0'
gem 'omniauth-google-oauth2', '~> 0.7.0'

gem 'jwt', '~> 2.0'

# contact mail form
gem 'recaptcha', require: 'recaptcha/rails'
gem 'mail_form'


# authorization
gem 'pundit'

# impersonate users
gem 'pretender'

# db annotations
gem 'annotate'

# Use Capistrano for deployment
gem 'capistrano-passenger', group: :development
gem 'capistrano-rails', group: :development
gem 'capistrano-rvm', group: :development
gem 'capistrano-yarn'
gem 'capistrano3-delayed-job', '~> 1.0'

# i18n
gem 'i18n-js', '~> 3.0.0.rc14'
gem 'rails-i18n'

# email exceptions
gem 'exception_notification'
gem 'httparty'
gem 'slack-notifier'

# css styles for emails
gem 'nokogiri'
gem 'premailer-rails'

# filtering
gem 'has_scope'

# generating zip files
gem 'rubyzip'

# add request server timings to the devtools
gem 'rails_server_timings'

# Maybe in Ruby
gem 'possibly'

# bootstrap tokenizer
gem 'bootstrap_tokenfield_rails'

# memcache
gem 'dalli'

# Generate 'random' values like usernames, emails, ...
gem 'faker', '~> 1.8'

group :development, :test do
  # Use mocha for stubbing and mocking
  gem 'mocha'
  # Factory bot for factories
  gem 'factory_bot'
  gem 'factory_bot_rails'

  # test template rendering
  gem 'rails-controller-testing'

  # I18N default locale & better test reporter
  # Remove git fork once the original gem is updated
  gem 'minitest-utils', git: 'https://github.com/rien/minitest-utils.git'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]

  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
end

group :test do
  # for measuring coverage
  gem 'simplecov', require: false
  gem 'minitest-ci'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'rb-readline' # require for irb
  gem 'rubocop'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # Manage processes (webpack, rails, delayed_job, ...)
  gem 'foreman'

  # for opening letters
  gem 'letter_opener'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# interfacing with docker
gem 'docker-api'

gem "actiontext", github: "rails/actiontext", require: "action_text"
gem "image_processing", "~> 1.2" # for Active Storage variants
