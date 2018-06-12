require_relative 'boot'

require 'rails/all'

require 'English'

# If no keyfile exists, copy the example file
# (with fake values) and generate a new base secret.

keyfile_example = 'config/keys.yml.example'
keyfile = 'config/keys.yml'

unless File.exist? keyfile
  example = YAML.load_file keyfile_example
  example['secret_key_base'] = SecureRandom.hex(64)
  File.write(keyfile, example.to_yaml)
end

SECRET_KEYS = YAML.load_file keyfile

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dodona
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.dodona_email = 'dodona@ugent.be'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    Rails.application.config.time_zone = 'Brussels'

    Rails.application.config.i18n.available_locales = %w[en nl]
    Rails.application.config.i18n.default_locale = :nl
    Rails.application.config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    Rails.application.config.autoload_paths += Dir[Rails.root.join('app', 'helpers', 'renderers')]
    Rails.application.config.autoload_paths += Dir[Rails.root.join('app', 'models', 'transient')]

    Rails.application.config.middleware.use I18n::JS::Middleware
  end
end
