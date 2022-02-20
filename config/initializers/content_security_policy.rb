# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self

    policy.frame_ancestors :none

    if Rails.env.development?
      # Allow webpack-dev-server
      policy.connect_src :self, Rails.configuration.tutor_url.to_s,
                         'https://*.googleapis.com',
                         'http://localhost:3035', 'ws://localhost:3035'
    else
      policy.connect_src :self, Rails.configuration.tutor_url.to_s
    end

    policy.font_src    :self, 'https://fonts.gstatic.com',
                       'https://cdn.jsdelivr.net/npm/@mdi/font@5.x/',
                       'https://cdn.jsdelivr.net/npm/mathjax@3/'

    policy.img_src     :self, :data, :https

    policy.object_src  :none

    policy.script_src  :self, :unsafe_inline, :unsafe_eval,
                       'https://cdn.jsdelivr.net/npm/mathjax@3/'

    policy.style_src   :self, :unsafe_inline,
                       'https://fonts.googleapis.com',
                       'https://cdn.jsdelivr.net/npm/@mdi/font@5.x/'
  end
  #   # Generate session nonces for permitted importmap and inline scripts
  #   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  #   config.content_security_policy_nonce_directives = %w(script-src)
  #
  #   # Report CSP violations to a specified URI. See:
  #   # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
  #   # config.content_security_policy_report_only = true
end

# Rails.application.config.content_security_policy_report_only = true
