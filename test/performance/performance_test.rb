require 'test_helper'
require 'rails/performance_test_help'

class PerformanceTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { runs: 5, metrics: [:wall_time, :memory],
  #                          output: 'tmp/performance', formats: [:flat] }

  setup do
    @user = create :zeus
    @courses = create_list(:course, 5, series_count: 10, exercises_per_series: 5, subscribed_members: [@user])
    sign_in @user
  end

  #test "homepage" do
  #  get '/'
  #end
end
