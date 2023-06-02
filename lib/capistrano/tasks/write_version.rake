namespace :my_tasks do
  desc "Sets the timestamp in version_file"
  task :set_version_info do
    version_file = "/home/dodona/rails/current/config/version.yml"
    execute :rm, version_file
    version = Time.now.strftime("%y.%m.%d%H%M")
    execute :echo, "'version: #{version}' >> #{version_file}"
  end
end

after 'deploy:symlink:shared', 'my_tasks:set_version_info'
