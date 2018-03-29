Delayed::Worker.destroy_failed_jobs = false # Keep failed jobs for logging
Delayed::Worker.sleep_delay = 5 # seconds sleep if no job, default 5
Delayed::Worker.max_attempts = 3 # default is 25
Delayed::Worker.max_run_time = 2.hours
Delayed::Worker.read_ahead = 2 # default is 5
Delayed::Worker.default_queue_name = 'default'
Delayed::Worker.raise_signal_exceptions = :term # on kill release job
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))
