set :dev

server 'mestra.ugent.be', user: 'dodona', roles: %i[web app db worker], ssh_options: {
    port: 4840
}

set :branch, ENV['BRANCH'] || 'develop'
set :rails_env, :development

set :delayed_job_workers, 3

set :bundle_without, ''

#set :linked_files, fetch(:linked_files, []).push('tmp/development_secret.txt')

# Perform yarn install before precompiling the assets in order to pass the
# integrity check.
# namespace :deploy do
#   namespace :assets do
#     before :precompile, :yarn_install do
#       on release_roles(fetch(:assets_roles)) do
#         within release_path do
#           with rails_env: fetch(:rails_env) do
#             execute :yarn, "install"
#           end
#         end
#       end
#     end
#   end
#   before :publishing, :asset_stuff do
#     on roles :web do
#       within release_path do
#         with rails_env: fetch(:rails_env) do
#           execute :rake, 'assets:nodigest'
#         end
#       end
#     end
#   end
# end
