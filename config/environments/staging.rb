Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # The main webapp
  config.default_host = 'naos.dodona.be'

  # alternative host name
  config.alt_host = 'naos.ugent.be'

  config.web_hosts = [config.default_host, config.alt_host]

  # The sandboxed host with user provided content, without authentication
  config.sandbox_host = 'naos-sandbox.dodona.be'

  # Allowed hostnames
  config.hosts << config.default_host << config.alt_host << config.sandbox_host

  # Where we host our assets (a single domain, for caching)
  config.action_controller.asset_host = 'naos.dodona.be'

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  config.action_controller.perform_caching = true
  config.action_controller.enable_fragment_cache_logging = true

  config.action_mailer.perform_caching = false

  config.cache_store = :mem_cache_store, {namespace: :"2"}
  config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
  }

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Compress JavaScripts and CSS.
  # config.assets.js_compressor = :terser

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  config.i18n.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  config.middleware.use ExceptionNotification::Rack,
                        ignore_if: ->(env, _exception) {env['HTTP_HOST'] == 'localhost:3000'},
                        ignore_notifier_if: {
                          email: lambda { |env, exception|
                            exception.is_a?(InternalErrorException) ||
                              exception.is_a?(SlowRequestException)
                          }
                        },
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
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.submissions_storage_path = Rails.root.join('data', 'storage', 'submissions')
end
