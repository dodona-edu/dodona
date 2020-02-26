# == Schema Information
#
# Table name: series
#
#  id                :integer          not null, primary key
#  course_id         :integer
#  name              :string(255)
#  description       :text(65535)
#  visibility        :integer
#  order             :integer          default("0"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deadline          :datetime
#  access_token      :string(255)
#  indianio_token    :string(255)
#  progress_enabled  :boolean          default("1"), not null
#  exercises_visible :boolean          default("1"), not null
#

require 'test_helper'

class SeriesTest < ActiveSupport::TestCase
  setup do
    stub_all_exercises!
    @series = create :series
  end

  test 'factory should create series' do
    assert_not_nil @series
  end

  test 'deadline? and pending? with deadlines in the future' do
    @series.deadline = Time.current + 2.minutes
    assert_equal true, @series.deadline?
    assert_equal true, @series.pending?
  end

  test 'deadline? and pending? with deadlines in the past' do
    @series.deadline = Time.current - 2.minutes
    assert_equal true, @series.deadline?
    assert_equal false, @series.pending?
  end

  test 'deadline? and pending? if there is no deadline' do
    @series.deadline = nil
    assert_equal false, @series.deadline?
    assert_equal false, @series.pending?
  end

  test 'factory should create series with submissions' do
    series = create :series, :with_submissions
    assert_not_empty series.course.submissions
  end

  test 'indianio_token should not be set' do
    assert_nil @series.indianio_token
  end

  test 'enabling indianio_support should generate a new token if there was none' do
    @series.indianio_support = true
    assert_not_nil @series.indianio_token

    @series.indianio_token = nil

    @series.indianio_support = '1'
    assert_not_nil @series.indianio_token

    @series.indianio_token = nil

    @series.indianio_support = 1
    assert_not_nil @series.indianio_token
  end

  test 'indianio_support should be true when there is a token' do
    @series.indianio_token = 'something'
    assert_equal true, @series.indianio_support?
  end

  test 'disabling indianio_support should set token to nil' do
    @series.indianio_token = 'something'
    @series.indianio_support = false
    assert_nil @series.indianio_token

    @series.indianio_token = 'something'

    @series.indianio_support = '0'
    assert_nil @series.indianio_token

    @series.indianio_token = 'something'

    @series.indianio_support = 0
    assert_nil @series.indianio_token
  end

  test 'generate_token should generate a new token' do
    indianio = 'indianio'
    access = 'access'
    @series.update(indianio_token: indianio, access_token: access)
    @series.generate_indianio_token
    assert_not_equal indianio, @series.indianio_token

    @series.generate_access_token
    assert_not_equal access, @series.access_token
  end

  test 'access_token should always be set' do
    @series.update(visibility: 'open')
    assert @series.access_token.present?
    @series.update(visibility: 'hidden')
    assert @series.access_token.present?
    @series.update(visibility: 'closed')
    assert @series.access_token.present?
  end

  test 'series scoresheet should be correct' do
    course = create :course
    create_list :series, 4, course: course, exercise_count: 5, deadline: Time.current
    users = create_list(:user, 4, courses: [course])

    course.series.each do |series|
      deadline = series.deadline
      series.exercises.map do |exercise|
        4.times do |i|
          u = users[i]
          case i
          when 0 # Wrong submission before deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes)
          when 1 # Correct submission before deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes)
          when 2 # Wrong submission after deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes)
          when 3 # Correct submission after deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes)
          end
        end
      end
    end
  end

  test 'completed? and solved_exercises with wrong submission before deadline' do
    series = create :series, exercise_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Wrong submission before deadline
    create :wrong_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline - 2.minutes)
    assert_equal false, series.completed?(user)
    assert_equal 0, series.solved_exercises(user).count
  end

  test 'completed? and solved_exercises with correct submission before deadline' do
    series = create :series, exercise_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Correct submission before deadline
    create :correct_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline - 2.minutes)
    assert_equal true, series.completed?(user)
    assert_equal 1, series.solved_exercises(user).count
  end

  test 'completed? and solved_exercises with wrong submission after deadline' do
    series = create :series, exercise_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Wrong submission after deadline
    create :wrong_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline + 2.minutes)
    assert_equal false, series.completed?(user)
    assert_equal 0, series.solved_exercises(user).count
  end

  test 'completed? and solved_exercises with correct submission after deadline' do
    series = create :series, exercise_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Correct submission after deadline
    create :correct_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline + 2.minutes)
    assert_equal true, series.completed?(user)
    assert_equal 1, series.solved_exercises(user).count
  end
end
