
# Create a logger for the delayed jobs
# https://stackoverflow.com/questions/14631910/logging-in-delayed-job
Delayed::Worker.logger = Logger.new(Rails.root / 'log' / 'dj.log')

