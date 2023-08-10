set :dev

server 'mestra.ugent.be', user: 'dodona', roles: %i[web app worker], ssh_options: {
    port: 4840
}

set :rails_env, :development

set :default_env, {skip_test_database: true}

set :delayed_job_workers, 1

set :bundle_without, ''

# Override ['config/master.key'] from main deploy file, we don't need it on mestra
set :linked_files, []

namespace :deploy do
  before :restart, :reset_db do
    on roles(:web) do
      within release_path do
        execute :rm, '-rf', 'data/exercises/*'
        execute :rm, '-rf', 'data/judges/*'
        execute :rm, '-rf', 'data/storage/*'
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
