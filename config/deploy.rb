# config valid only for current version of Capistrano
lock '~> 3.9'

set :application, 'dodona'
set :repo_url, 'git@github.com:dodona-edu/dodona.git'

# Default branch is :main
set :branch, ENV['GITHUB_SHA'] || 'main'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, '/home/dodona/rails'

# RVM is installed globally using apt
set :rvm_custom_path, '/usr/share/rvm'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/master.key')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system', 'data/exercises', 'data/judges', 'data/storage', 'node_modules')

set :passenger_restart_with_touch, true

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Number of delayed_job workers
# default value: 1
# set :delayed_job_workers, 5
set :delayed_job_roles, [:worker]

# String to be prefixed to worker process names
# This feature allows a prefix name to be placed in front of the process.
# For example:  reports/delayed_job.0  instead of just delayed_job.0
# set :delayed_job_prefix, 'reports'

# Delayed_job queue or queues
# Set the --queue or --queues option to work from a particular queue.
# default value: nil
# set :delayed_job_queues, ['mailer','tracking']

# Specify different pools
# You can use this option multiple times to start different numbers of workers
# for different queues.
# NOTE: When using delayed_job_pools, the settings for delayed_job_workers and
# delayed_job_queues are ignored.
# default value: nil
#
# Single pool of 3 workers looking at all queues: (when alone, '*' is a
# special case meaning any queue)
# set :delayed_job_pools, { '*' => 3 }
# set :delayed_job_pools, { '' => 3 }
# set :delayed_job_pools, { nil => 3 }
#
# Several queues, some with their own dedicated pools: (symbol keys will be
# converted to strings)
# set :delayed_job_pools, {
#     :mailer => 2,    # 2 workers looking only at the 'mailer' queue
#     :tracking => 1,  # 1 worker exclusively for the 'tracking' queue
#     :* => 2          # 2 on any queue (including 'mailer' and 'tracking')
# }
#
# Several workers each handling one or more queues:
# set :delayed_job_pools, {
#     'high_priority' => 1,                # one just for the important stuff
#     'high_priority,*' => 1,              # never blocked by low_priority jobs
#     'high_priority,*,low_priority' => 1, # works on whatever is available
#     '*,low_priority' => 1,  # high_priority doesn't starve the little guys
#   }
# Identification is assigned in order 0..3.
# Note that the '*' in this case is actually a queue with that name and does
# not mean any queue as it is not used alone, but alongside other queues.

# Set the roles where the delayed_job process should be started
# default value: :app
# set :delayed_job_roles, [:app, :background]

# Set the location of the delayed_job executable
# Can be relative to the release_path or absolute
# default value: 'bin'
# set :delayed_job_bin_path, 'script' # for rails 3.x

# To pass the `-m` option to the delayed_job executable which will cause each
# worker to be monitored when daemonized.
# set :delayed_job_monitor, true

### Set the location of the delayed_job.log logfile
# default value: "#{Rails.root}/log" or "#{Dir.pwd}/log"
# set :delayed_log_dir, 'path_to_log_dir'

### Set the location of the delayed_job pid file(s)
# default value: "#{Rails.root}/tmp/pids" or "#{Dir.pwd}/tmp/pids"
# set :delayed_job_pid_dir, 'path_to_pid_dir'

namespace :deploy do
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end

version = Time.now.strftime("%y.%m.%d-%H:%M")

namespace :deploy do
  before :publishing, :set_version do
    on roles :app do
      within release_path do
        execute :sed, "-i 's/VERSION = .*/VERSION = \"#{version}\".freeze/' config/initializers/00_version.rb"
      end
    end
  end
end
