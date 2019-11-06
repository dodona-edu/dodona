SecureHeaders::Configuration.default do |config|
  config.csp = {
    preserve_schemes: true,

    default_src: %w('self'),
    frame_ancestors: %w('none'),
    connect_src: %w('self' https://pandora.ugent.be
      https://dodona-cea23.firebaseio.com https://www.google-analytics.com),
    font_src: %w(data: https://fonts.gstatic.com
      https://cdn.materialdesignicons.com  https://cdnjs.cloudflare.com),
    img_src: %w('self' data: https://cdnjs.cloudflare.com),
    script_src: %w('self' 'unsafe-inline' 'unsafe-eval'
    https://www.google-analytics.com https://cdnjs.cloudflare.com),
    style_src: %w('self' 'unsafe-inline' https://fonts.googleapis.com
      https://cdn.materialdesignicons.com),
  }
end

SecureHeaders::Configuration.named_append(:captcha) do |request|
  {
    script_src: %w(https://www.recaptcha.net https://www.gstatic.com
      https://www.google.com),
    frame_src: %w(https://www.google.com)
  }
end

SecureHeaders::Configuration.named_append(:embeds_iframe) do |request|
  {
    frame_src: [
      "#{request.protocol}#{Rails.configuration.sandbox_host}:#{request.port}"
    ]
  }
end

SecureHeaders::Configuration.override(:sandbox) do |config|
  sources = %w('self' 'unsafe-inline' https:)
  sources << 'http:' if Rails.env.development?
  config.csp = {
    default_src: sources,
    script_src: sources,
  }
end

SecureHeaders::Configuration.named_append(:is_embedded) do |request|
  {
    frame_ancestors: [
      "#{request.protocol}#{Rails.configuration.default_host}:#{request.port}"
    ]
  }
end
