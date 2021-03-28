set :dev

server 'mestra.ugent.be', user: 'dodona', roles: %i[web app worker], ssh_options: {
    port: 4840
}

set :branch, ENV['GITHUB_SHA'] || 'develop'
set :rails_env, :development

set :delayed_job_workers, 3

set :bundle_without, ''

#set :linked_files, fetch(:linked_files, []).push('tmp/development_secret.txt')

namespace :deploy do
  before :restart, :reset_db do
    on roles(:web) do
      within release_path do
        execute :rake, 'db:reset'
      end
    end
  end
  before :restart, :mv_robots do
    on roles(:web) do
      within release_path do
        execute :mv, 'public/robots.development.txt', 'public/robots.txt'
      end
    end
  end
end
