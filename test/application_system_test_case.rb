require 'test_helper'
require 'selenium/webdriver'

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--window-size=1400,1400')
  options.add_argument('--disable-gpu')
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')

  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = 120 # instead of the default 60 end
  Capybara::Selenium::Driver.new(app,
                                 browser: :chrome,
                                 options: options, http_client: client)
end

Capybara.configure do |config|
  config.default_max_wait_time = 10
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :chrome
end
