require 'application_system_test_case'
require 'capybara/rails'

class GenericSystemTest < ApplicationSystemTestCase
  setup do
    Rails.application.config.default_host = '127.0.0.1'
  end
end
