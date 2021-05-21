namespace :assets do
  desc "don't digest the assets"
  task nodigest: :environment do
    assets_path = File.join(Rails.root, 'public', Rails.configuration.assets.prefix)
    Rails.configuration.assets.nodigest.each do |asset|
      source = File.join('app/assets/javascripts', asset)
      dest = File.join(assets_path, asset)
      FileUtils.copy_file(source, dest)
    end
  end
end
