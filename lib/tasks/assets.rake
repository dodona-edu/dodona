namespace :assets do
  desc "don't digest the assets"
  task nodigest: :environment do
    assets_path = File.join(Rails.root, 'public', Rails.configuration.assets.prefix)
    Rails.configuration.assets.nodigest.each do |asset|
      Dir.glob(File.join('app/assets/builds', asset)).each do |source_path|
        file_name = File.basename(source_path)
        dest_path = File.join(assets_path, file_name)
        FileUtils.copy_file(source_path, dest_path)
      end
    end
  end
end
