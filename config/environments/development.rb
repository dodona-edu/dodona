require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = true

  # Application hosts

  config.hosts << ENV['RAILS_APPLICATION_HOST'] if ENV['RAILS_APPLICATION_HOST'].present?
  config.hosts << ENV['RAILS_SANDBOX_HOST'] if ENV['RAILS_SANDBOX_HOST'].present?

  # The main webapp
  config.default_host = ENV['RAILS_APPLICATION_HOST'] || 'dodona.localhost'
  config.action_mailer.default_url_options = { host: ENV['RAILS_APPLICATION_HOST'] || 'dodona.localhost:3000' }

  # The sandboxed host with user provided content, without authentication
  config.sandbox_host = ENV['RAILS_SANDBOX_HOST'] || 'sandbox.localhost'
  config.tutor_url = URI::HTTP.build(host: 'tutor.localhost', port: 8080, path: '/cgi-bin/build_trace.py')

  # Where we host our assets (a single domain, for caching)
  # Port is needed somehow...
  config.action_controller.asset_host = ENV['RAILS_APPLICATION_HOST'] || 'dodona.localhost:3000'

  # In the development environment your application's code is reloaded any time
  # it changes. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Creates IllegalStateError on simultaneous requests (see https://github.com/dpogue/rails_server_timings/issues/6)
  config.server_timings.enabled = false

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist? || ENV['RAILS_DO_CACHING'].present?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :mem_cache_store, { namespace: :"2" }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true # TODO CHECK IF STILL NEEDED

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations.
  config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Regenerate js translation files
  config.middleware.use I18n::JS::Middleware

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker # TODO CHECK IF STILL NEEDED

  # Uncomment if you wish to allow Action Cable access from any origin.
  # config.action_cable.disable_request_forgery_protection = true

  # Exception notifications
  config.middleware.use ExceptionNotification::Rack,
                        ignore_if: ->(env, _exception) { env['HTTP_HOST'] == 'localhost:3000' || env['HTTP_HOST'] == 'dodona.localhost:3000' },
                        email: {
                          email_prefix: '[Dodona-dev] ',
                          sender_address: %("Dodona" <dodona@ugent.be>),
                          exception_recipients: %w[dodona@ugent.be]
                        }
  config.action_mailer.delivery_method = :letter_opener
  # Defaults to:
  # config.action_mailer.sendmail_settings = {
  #   :location => '/usr/sbin/sendmail',
  #   :arguments => '-i -t'
  # }
  if ENV['RAILS_NO_ACTION_MAILER'].present?
    config.action_mailer.perform_deliveries = false
  else
    config.action_mailer.perform_deliveries = true
  end
  config.action_mailer.raise_delivery_errors = true

  config.submissions_storage_path = Rails.root.join('data', 'storage', 'submissions')
end
