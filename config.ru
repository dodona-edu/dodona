# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

DelayedJobWeb.use Rack::Auth::Basic do |username, password|
  username == 'djdj' && password == 'djdj'
end

# Action Cable requires that all classes are loaded in advance
Rails.application.eager_load!

run Rails.application
