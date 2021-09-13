Hcaptcha.configure do |config|
  config.site_key = Rails.application.credentials.hcaptcha_site_key
  config.secret_key = Rails.application.credentials.hcaptcha_secret_key
end
