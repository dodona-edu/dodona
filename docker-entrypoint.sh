#!/bin/sh
set -euxo

# Move into the directory of the application.
cd /app

# Remove the previous server pid if this somehow still exists.
rm -f /app/tmp/pids/server.pid

# Seed the database.
rails db:environment:set RAILS_ENV=development
RAILS_ENV=development bundle exec rails db:reset

# Start the server in development mode.
RAILS_ENV=development bundle exec rails server -b 0.0.0.0