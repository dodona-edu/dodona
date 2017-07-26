ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'faker'
require 'rails/test_help'
require 'mocha/mini_test'
require 'helpers/stub_helper'

# Always generate the same testdata
Faker::Config.random = Random.new(42)

class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Add more helper methods to be used by all tests here...
  include StubHelper
end
