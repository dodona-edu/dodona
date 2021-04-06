set :stage, :dev

server 'naos.ugent.be', user: 'dodona', roles: %i[web app db worker], ssh_options: {
    port: 4840
}

set :branch, ENV['BRANCH'] || 'develop'
set :rails_env, :staging

set :default_env, {node_env: 'production'}

set :delayed_job_workers, 3

set :linked_files, fetch(:linked_files, []).push('config/credentials/staging.key')

# Perform yarn install before precompiling the assets in order to pass the
# integrity check.
namespace :deploy do
  before :restart, :mv_robots do
    on roles(:web) do
      within release_path do
        execute :mv, 'public/robots.development.txt', 'public/robots.txt'
      end
    end
  end
end
