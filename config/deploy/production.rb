# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server 'dodona.ugent.be',   user: 'dodona', port: '4840', roles: %w[app web db worker]
server 'sisyphus.ugent.be', user: 'dodona', port: '4840', roles: %w[app worker]
server 'salmoneu.ugent.be', user: 'dodona', port: '4840', roles: %w[app worker]
server 'tantalus.ugent.be', user: 'dodona', port: '4840', roles: %w[app worker]
server 'ixion.ugent.be',    user: 'dodona', port: '4840', roles: %w[app worker]
server 'tityos.ugent.be',   user: 'dodona', port: '4840', roles: %w[app worker]

set :branch, 'master'

set :delayed_job_pools_per_server,
    'dodona' => {
      'default,git,statistics,exports,cleaning' => 2
    },
    'sisyphus' => {
      'submissions,low_priority_submissions,high_priority_submissions' => 6
    },
    'salmoneus' => {
      'submissions,low_priority_submissions,high_priority_submissions' => 6
    },
    'tantalus' => {
      'submissions,low_priority_submissions,high_priority_submissions' => 6
    },
    'ixion' => {
      'submissions,low_priority_submissions,high_priority_submissions' => 6
    },
    'tityos' => {
      'submissions,low_priority_submissions,high_priority_submissions' => 6
    }

# server 'example.com', user: 'deploy', roles: %w{app web}, other_property: :other_value
# server 'db.example.com', user: 'deploy', roles: %w{db}

# role-based syntax
# ==================

# Defines a role with one or multiple servers. The primary server in each
# group is considered to be the first unless any  hosts have the primary
# property set. Specify the username and a domain or IP for the server.
# Don't use `:all`, it's a meta role.

# role :app, %w{deploy@example.com}, my_property: :my_value
# role :web, %w{user1@primary.com user2@additional.com}, other_property: :other_value
# role :db,  %w{deploy@example.com}

# Configuration
# =============
# You can set any configuration variable like in config/deploy.rb
# These variables are then only loaded and set in this stage.
# For available Capistrano configuration variables see the documentation page.
# http://capistranorb.com/documentation/getting-started/configuration/
# Feel free to add new variables to customise your setup.

namespace :deploy do
  before :publishing, :asset_stuff do
    on roles :web do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, 'assets:nodigest'
        end
      end
    end
  end
end

# Custom SSH Options
# ==================
# You may pass any option but keep in mind that net/ssh understands a
# limited set of options, consult the Net::SSH documentation.
# http://net-ssh.github.io/net-ssh/classes/Net/SSH.html#method-c-start
#
# Global options
# --------------
#  set :ssh_options, {
#    keys: %w(/home/rlisowski/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
#
# The server-based syntax can be used to override options:
# ------------------------------------
# server 'example.com',
#   user: 'user_name',
#   roles: %w{web app},
#   ssh_options: {
#     user: 'user_name', # overrides user setting above
#     keys: %w(/home/user_name/.ssh/id_rsa),
#     forward_agent: false,
#     auth_methods: %w(publickey password)
#     # password: 'please use keys'
#   }
