require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Dodona
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.dodona_email = 'dodona@ugent.be'

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # Application hosts

    # The main webapp
    config.default_host = 'dodona.localhost'

    # The sandboxed host with user provided content, without authentication
    config.sandbox_host = 'sandbox.localhost'

    # Where we host our assets (a single domain, for caching)
    # Port is needed somehow...
    config.action_controller.asset_host = 'dodona.localhost:3000'

    config.time_zone = 'Brussels'

    config.i18n.available_locales = %w[en nl]
    config.i18n.default_locale = :nl
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]

    config.eager_load_paths += Dir[Rails.root.join('app', 'helpers', 'renderers')]
    config.eager_load_paths += Dir[Rails.root.join('app', 'models', 'transient')]

    config.active_job.queue_adapter = :delayed_job

    config.active_storage.queues.analysis = :default
    config.active_storage.queues.purge    = :default

    config.action_view.default_form_builder = "StandardFormBuilder"
  end
end
