require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
WebMock.disable!

module Dodona
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    config.dodona_email = 'dodona@ugent.be'
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Application hosts

    # The main webapp
    config.default_host = 'dodona.localhost'

    # The sandboxed host with user provided content, without authentication
    config.sandbox_host = 'sandbox.localhost'
    config.tutor_url = URI::HTTP.build(host: 'tutor.localhost', port: 8080, path: "/cgi-bin/build_trace.py")

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
