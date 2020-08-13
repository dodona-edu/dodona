# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self

  policy.frame_ancestors :none

  if Rails.env.development?
    # Allow webpack-dev-server
    policy.connect_src :self, 'https://pandora.ugent.be',
                       'https://www.google-analytics.com',
                       'https://*.googleapis.com',
                       'http://localhost:3035', 'ws://localhost:3035'
  else
    policy.connect_src :self, 'https://pandora.ugent.be',
                       'https://www.google-analytics.com',
                       'https://*.googleapis.com'
  end

  policy.font_src    :self, 'https://fonts.gstatic.com',
                     'https://cdn.materialdesignicons.com',
                     'https://cdn.jsdelivr.net/npm/mathjax@3/'

  policy.img_src     :self, :data, :https

  policy.object_src  :none

  policy.script_src  :self, :unsafe_inline, :unsafe_eval,
                     'https://www.google-analytics.com',
                     'https://cdn.jsdelivr.net/npm/mathjax@3/'

  policy.style_src   :self, :unsafe_inline, 'https://fonts.googleapis.com',
                     'https://cdn.materialdesignicons.com'
end

# Rails.application.config.content_security_policy_report_only = true

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Set the nonce only to specific directives
# Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
