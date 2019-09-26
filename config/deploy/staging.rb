set :stage, :dev

server 'naos.ugent.be', user: 'dodona', roles: %i[web app db worker], ssh_options: {
    port: 4840
}

set :branch, ENV['BRANCH'] || 'develop'
set :rails_env, :staging

set :delayed_job_workers, 3

# Development mode doesn't use the `secret_key_base` stored in the credentials, but we would still like a stable key.
set :linked_files, fetch(:linked_files, []).push('tmp/development_secret.txt')

# Perform yarn install before precompiling the assets in order to pass the
# integrity check.
namespace :deploy do
  namespace :assets do
    before :precompile, :yarn_install do
      on release_roles(fetch(:assets_roles)) do
        within release_path do
          with rails_env: fetch(:rails_env) do
            execute :yarn, "install"
          end
        end
      end
    end
  end
end
