require File.expand_path('../boot', __FILE__)

require 'rails/all'

require "English"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dodona
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    Rails.application.config.action_controller.default_url_options = { trailing_slash: true }

    Rails.application.config.i18n.available_locales = %w(en nl)
    Rails.application.config.i18n.default_locale = :nl
  end
end
