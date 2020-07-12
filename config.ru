# This file is used by Rack-based servers to start the application.

require ::File.expand_path('config/environment', __dir__)

# Action Cable requires that all classes are loaded in advance
Rails.application.eager_load!

run Rails.application

$stdout.sync = true
