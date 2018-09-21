set :stage, :dev

# don't specify db as it's not needed for unipept
server 'naos.ugent.be', user: 'dodona', roles: %i[web app db worker], ssh_options: {
  port: 4840
}

set :branch, ENV['BRANCH'] || 'develop'
set :rails_env, :development

set :delayed_job_workers, 3

namespace :tutor do
    desc 'Starting tutor'
    task :tutor do
        on roles(:web) do
            execute :screen, "-dm docker run --rm -p 8080:8080 python-tutor-webservice"
        end
    end
end

after "deploy", "tutor:tutor"

