require 'test_helper'
require 'rails/performance_test_help'
require 'minitest/hooks/test'

class PerformanceTest < ActionDispatch::PerformanceTest
  include Minitest::Hooks
  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }

  around(:all) do |&block|
    ActiveRecord::Base.transaction do
      puts "\n[Seeding fake data for performance test]"
      load "#{Rails.root}/db/seed_fake_data.rb"
      super(&block)
      raise ActiveRecord::Rollback
    end
  end

  before do
    @user = User.first # should be Zeus
    sign_in @user
    @course = Course.first
  end

  test "homepage" do
    get '/'
  end

  test "course page" do
    get course_url(@course)
  end

  test "homepage json" do
    get '/', params: { format: :json }
  end
end
