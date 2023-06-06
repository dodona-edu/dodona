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
      yml = { 'version' => Time.now.strftime("%y.%m.%d%H%M")}
      puts "Creating version.yml, with version #{yml['version']}"
      puts(execute :pwd)
      puts "Release path: #{release_path}"
      puts "Current path: #{current_path}"
    end
  end
end

after 'git:create_release', 'create_version_yml'
