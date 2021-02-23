# Default environment is development
ENV['RAILS_ENV'] ||= 'development'
# Set NODE_ENV to match 'RAILS_ENV'
# Staging builds in production mode
ENV['NODE_ENV'] = 'production' unless ENV['RAILS_ENV'] == 'development'

# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!
