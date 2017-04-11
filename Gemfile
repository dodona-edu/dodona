source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.0.0'
# Use mysql as the database for Active Record
gem 'mysql2', '>= 0.3.18', '< 0.5'
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
gem 'less-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# used to validate container responses
gem 'json-schema'

# delayed jobs
gem 'delayed_job_active_record'
# start workers in the background
gem 'daemons'
# dashboard
github 'sinatra/sinatra' do
  gem 'sinatra'
  gem 'rack-protection'
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
gem 'diffy'

# code editor
gem 'ace-rails-ap'

# auto css prefixer
gem 'autoprefixer-rails'

# cas authentication
gem 'devise'
gem 'devise_cas_authenticatable'
gem 'rubycas-client', git: 'https://github.com/bmesuere/rubycas-client.git'

# authorization
gem 'pundit'

# impersonate users
gem 'pretender'

# db annotations
gem 'annotate'

# Use Capistrano for deployment
gem 'capistrano-rails', group: :development
gem 'capistrano-passenger', group: :development
gem 'capistrano-rvm', group: :development
gem 'capistrano3-delayed-job', '~> 1.0'

# i18n
gem 'rails-i18n'
gem 'i18n-js', '~> 3.0.0.rc14'

# email exceptions
gem 'exception_notification'
gem 'slack-notifier'

# filtering
gem 'has_scope'

# generating zip files
gem 'rubyzip'

# add request server timings to the devtools
gem 'rails_server_timings'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rubocop'
  gem 'rb-readline' # require for irb
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# interfacing with docker
gem 'docker-api'
