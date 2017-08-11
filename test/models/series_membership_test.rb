# == Schema Information
#
# Table name: series_memberships
#
#  id              :integer          not null, primary key
#  series_id       :integer
#  exercise_id     :integer
#  order           :integer          default(999)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  users_correct   :integer
#  users_attempted :integer
#

require 'test_helper'

class SeriesMembershipTest < ActiveSupport::TestCase
  setup do
    @course = create :course
    @series = create :series, course: @course
    @exercise = create :exercise, series: [@series]
    @membership = @series.series_memberships.first

    create_list(:user, 5, courses: [@course]).each do |user|
      create :wrong_submission,
             user: user,
             course: @course,
             exercise: @exercise
    end

    create_list(:user, 5, courses: [@course]).each do |user|
      create :correct_submission,
             user: user,
             course: @course,
             exercise: @exercise
    end
  end

  test 'cached methods should not call the cachee' do
    users_tried = @membership.cached_users_tried
    users_correct = @membership.cached_users_correct

    Exercise.any_instance.expects(:users_tried).never
    Exercise.any_instance.expects(:users_correct).never

    assert_equal users_tried, @membership.cached_users_tried
    assert_equal users_correct, @membership.cached_users_correct
  end

  test 'invalidation should call cachee' do
    users_tried = @membership.cached_users_tried
    users_correct = @membership.cached_users_correct

    @membership.invalidate_stats_cache

    Exercise.any_instance.expects(:users_tried).once.returns(users_tried)
    Exercise.any_instance.expects(:users_correct).once.returns(users_correct)

    10.times do
      assert_equal users_tried, @membership.cached_users_tried
      assert_equal users_correct, @membership.cached_users_correct
    end
  end

  test 'cache should be invalidated' do
  end
end
