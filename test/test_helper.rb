require 'simplecov'
SimpleCov.start 'rails'

require_relative '../config/environment'
require 'faker'
require 'rails/test_help'
require 'mocha/minitest'

require 'helpers/stub_helper'
require 'helpers/delayed_job_helper'
require 'helpers/crud_helper'
require 'helpers/git_helper'
require 'helpers/remote_helper'
require 'helpers/series_zip_helper'

# automatically set locale for all routes
require 'minitest/utils/rails/locale'

# Always generate the same testdata
Faker::Config.random = Random.new(42)

OmniAuth.config.test_mode = true

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include StubHelper
  include DelayedJobHelper
  include RemoteHelper
  include SeriesZipHelper

  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
