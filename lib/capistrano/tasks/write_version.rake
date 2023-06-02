# namespace :my_tasks do
#   desc "Sets the timestamp in version_file"
#   task :set_version_info do
#     version_file = "#{current_path}/config/version.yml"
#     File.delete(version_file) if File.exist?(version_file)
#     yml = { 'version' => Time.now.strftime("%y.%m.%d%H%M")}
#     File.write(version_file, yml.to_yaml)
#   end
# end
task :create_version_yml do
  on roles(:web) do
    within(shared_path) do
      version_file = "config/version.yml"
      File.delete(version_file) if File.exist?(version_file)
      yml = { 'version' => Time.now.strftime("%y.%m.%d%H%M")}
      File.write(version_file, yml.to_yaml)
    end
  end
end

after 'deploy:symlink:linked_dirs', 'create_version_yml'
