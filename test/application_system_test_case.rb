require 'test_helper'
require 'selenium/webdriver'

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--window-size=1400,1400')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')

  # Debug options
  # options.add_argument('--auto-open-devtools-for-tabs')
  options.add_argument('--headless')

  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 180 # instead of the default 60 end
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 options: options, http_client: client)
end

Capybara.configure do |config|
  config.default_max_wait_time = 10
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :chrome

  setup do
    @default_host = Rails.application.config.default_host
    @sandbox_host = Rails.application.config.sandbox_host
    Rails.application.config.default_host = '127.0.0.1'
    Rails.application.config.sandbox_host = '127.0.0.1'
    @forgery = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @forgery
    Rails.application.config.sandbox_host = @sandbox_host
    Rails.application.config.default_host = @default_host
  end
end
