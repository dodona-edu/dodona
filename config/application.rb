require_relative 'boot'

require 'rails/all'

require 'English'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dodona
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    Rails.application.config.time_zone = 'Brussels'

    Rails.application.config.i18n.available_locales = %w(en nl)
    Rails.application.config.i18n.default_locale = :nl
    Rails.application.config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    Rails.application.config.autoload_paths += Dir[Rails.root.join('app', 'helpers', 'renderers')]

    Rails.application.config.middleware.use I18n::JS::Middleware
  end
end
