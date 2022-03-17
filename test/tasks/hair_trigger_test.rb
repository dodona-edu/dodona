require 'test_helper'

class HairTriggerTest < ActiveSupport::TestCase
  test 'Migrations/schema.rb should match triggers in models' do
    assert HairTrigger.migrations_current?
  end
end
