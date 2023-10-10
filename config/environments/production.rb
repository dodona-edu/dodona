require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # The main webapp
  config.default_host = 'dodona.be'
  config.action_mailer.default_url_options = { host: 'dodona.be' }

  # alternative host name
  config.alt_host = 'dodona.ugent.be'

  config.web_hosts = [config.default_host, config.alt_host]

  # The sandboxed host with user provided content, without authentication
  config.sandbox_host = 'sandbox.dodona.be'
  config.tutor_url = URI::HTTPS.build(host: 'pandora.ugent.be', path: '/tutor/cgi-bin/build_trace.py')

  # Where we host our assets (a single domain, for caching)
  config.action_controller.asset_host = 'dodona.be'

  # Allowed hostnames
  config.hosts << config.default_host << config.sandbox_host << config.alt_host

  # Where we host our assets (a single domain, for caching)
  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  config.asset_host = 'dodona.be'

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  config.require_master_key = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Log to STDOUT by default
  # config.logger = ActiveSupport::Logger.new(STDOUT)
  #   .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
  #   .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Use a different cache store in production.
  config.cache_store = :mem_cache_store, 'calliope.ugent.be', {namespace: :"2"}

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "dodona_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Log disallowed deprecations.
  config.active_support.disallowed_deprecation = :log

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]

  config.middleware.use ExceptionNotification::Rack,
                        ignore_crawlers: %w[Googlebot BingPreview bingbot Applebot],
                        ignore_if: lambda { |env, exception|
                          env['action_controller.instance'].is_a?(PagesController) &&
                            env['action_controller.instance'].action_name == 'create_contact' &&
                            exception.is_a?(ActionController::InvalidAuthenticityToken)
                        },
                        email: {
                            email_prefix: '[Dodona] ',
                            sender_address: %("Dodona" <dodona@ugent.be>),
                            exception_recipients: %w[dodona@ugent.be]
                        },
                        slack: {
                            webhook_url: Rails.application.credentials[:slack_notifications_url],
                            channel: '#notifications',
                            username: 'Dodona-server',
                            additional_parameters: {
                              icon_url: 'https://dodona.be/icon.png',
                              mrkdwn: true
                            }
                        }


  config.action_mailer.delivery_method = :sendmail
  # Defaults to:
  # config.action_mailer.sendmail_settings = {
  #   :location => '/usr/sbin/sendmail',
  #   :arguments => '-i -t'
  # }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.deliver_later_queue_name = 'default'

  config.submissions_storage_path = Rails.root.join('data', 'storage', 'submissions')
end
