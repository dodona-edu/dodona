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
