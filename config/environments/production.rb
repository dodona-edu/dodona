Rails.application.configure do
  # Verifies that versions and hashed value of the package contents in the project's package.json
  config.webpacker.check_yarn_integrity = false
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true


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
  config.assets.js_compressor = :uglifier
  config.assets.js_compressor = Uglifier.new(harmony: true) if defined? Uglifier
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # `config.assets.precompile` and `config.assets.version` have moved to config/initializers/assets.rb

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # Mount Action Cable outside main process or domain
  # config.action_cable.mount_path = nil
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    config.logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
  end

  # Use a different cache store in production.
  config.cache_store = :mem_cache_store, 'elysium.ugent.be', {namespace: :"1"}

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "dodona_#{Rails.env}"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = [I18n.default_locale]

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Do not add server timings in production
  config.server_timings.enabled = false

  config.middleware.use ExceptionNotification::Rack,
                        ignore_if: ->(env, exception) {
                          env['action_controller.instance'].is_a?(PagesController) &&
                              env['action_controller.instance'].action_name == 'create_contact' &&
                              exception.is_a?(ActionController::InvalidAuthenticityToken)
                        },
                        email: {
                            email_prefix: '[Dodona] ',
                            sender_address: %("Dodona" <dodona@ugent.be>),
                            exception_recipients: %w[dodona@ugent.be]
                        },
                        mattermost: {
                            webhook_url: 'https://mattermost.zeus.gent/hooks/fh8wjui63p89byf1dp5ecs735h',
                            username: 'Dodona-server',
                            avatar: 'https://dodona.ugent.be/icon.png'
                        },
                        slack: {
                            webhook_url: 'https://hooks.slack.com/services/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',
                            channel: '#dodona',
                            username: 'Dodona-server',
                            additional_parameters: {
                                icon_url: 'https://dodona.ugent.be/icon.png',
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
