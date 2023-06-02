namespace :my_tasks do
  desc "Sets the timestamp in version_file"
  task :set_version_info do
    version_file = "/home/dodona/rails/current/config/version.yml"
    File.delete(version_file) if File.exist?(version_file)
    yml = { 'version' => Time.now.strftime("%y.%m.%d%H%M")}
    File.write(version_file, yml.to_yaml)
  end
end

after 'deploy:symlink:shared', 'my_tasks:set_version_info'