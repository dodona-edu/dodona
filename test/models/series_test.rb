# == Schema Information
#
# Table name: series
#
#  id                 :integer          not null, primary key
#  course_id          :integer
#  name               :string(255)
#  description        :text(65535)
#  visibility         :integer
#  order              :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  deadline           :datetime
#  access_token       :string(255)
#  indianio_token     :string(255)
#  progress_enabled   :boolean          default(TRUE), not null
#  activities_visible :boolean          default(TRUE), not null
#

require 'test_helper'

class SeriesTest < ActiveSupport::TestCase
  setup do
    stub_all_activities!
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

  test 'changing deadline should invalidate exercise statuses' do
    course = create :course
    series = create :series, course: course, deadline: Time.zone.now + 1.day, activity_count: 1
    user = create :user

    create :correct_submission,
           created_at: Time.zone.now,
           course: course,
           exercise: series.exercises[0],
           user: user

    assert_equal true, series.completed_before_deadline?(user)

    series.update(deadline: Time.zone.now - 1.day)

    assert_equal false, series.completed_before_deadline?(user)
  end

  test 'changing deadline and restoring should restore completion status' do
    original_deadline = Time.zone.now + 1.day

    course = create :course
    series = create :series, course: course, deadline: original_deadline
    user = create :user

    content_page = create :content_page
    series.content_pages << content_page

    # Complete the content page.
    now = Time.zone.now
    ActivityReadState.create activity: content_page,
                             course: course,
                             user: user

    assert_equal true, series.completed_before_deadline?(user)

    series.update(deadline: now - 1.day)

    assert_equal false, series.completed_before_deadline?(user)

    # Reset the deadline to the original one to ensure the status was not removed.
    series.update(deadline: original_deadline)

    assert_equal true, series.completed_before_deadline?(user)
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
    create_list :series, 2, course: course, activity_count: 2, deadline: Time.current
    users = create_list(:user, 6, courses: [course])

    expected_submissions = {}

    course.series.each do |series|
      deadline = series.deadline
      expected_submissions[series.id] = []
      series.exercises.map do |exercise|
        6.times do |i|
          u = users[i]
          case i
          when 0 # Wrong submission before deadline
            s = create :wrong_submission,
                       exercise: exercise,
                       user: u,
                       created_at: (deadline - 2.minutes),
                       course: course
            expected_submissions[series.id] << s.id
          when 1 # Wrong, then correct submission before deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes),
                   course: course
            s = create :correct_submission,
                       exercise: exercise,
                       user: u,
                       created_at: (deadline - 1.minute),
                       course: course
            expected_submissions[series.id] << s.id
          when 2 # Wrong submission after deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes),
                   course: course
          when 3 # Correct submission after deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes),
                   course: course
          when 4 # Correct submission before deadline not in course
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes)
          when 5 # Correct submission after deadline not in course
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline + 2.minutes)
          end
        end
      end

      scoresheet = series.scoresheet
      # All users are included in the scoresheet.
      assert_equal users.to_set, scoresheet[:users].to_set
      # All exercises are included in the scoresheet.
      assert_equal series.activities.to_set, scoresheet[:activities].to_set
      # Only latest submissions in the course and after the deadline are counted.
      assert_equal 2 * series.exercises.count, scoresheet[:submissions].count
      # Submissions are for the correct user.
      assert_equal users[0, 2].map(&:id).to_set, scoresheet[:submissions].keys.map(&:first).to_set
      # Expected submissions are returned.
      assert_equal expected_submissions[series.id].to_set, scoresheet[:submissions].values.map(&:id).to_set
      # Hash mapping is correct.
      scoresheet[:submissions].each do |key, submission|
        assert_equal [submission.user_id, submission.exercise.id], key
      end
    end
  end

  test 'completed? with wrong submission before deadline' do
    series = create :series, activity_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Wrong submission before deadline
    create :wrong_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline - 2.minutes)
    assert_equal false, series.completed?(user: user)
  end

  test 'completed? with correct submission before deadline within a course' do
    series = create :series, activity_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Correct submission before deadline
    create :correct_submission,
           course: series.course,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline - 2.minutes)
    assert_equal true, series.completed?(user: user)
  end

  test 'completed? with correct submission before deadline without course' do
    series = create :series, activity_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Correct submission before deadline
    create :correct_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline - 2.minutes)
    assert_equal false, series.completed?(user: user)
  end

  test 'completed? with wrong submission after deadline' do
    series = create :series, activity_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Wrong submission after deadline
    create :wrong_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline + 2.minutes)
    assert_equal false, series.completed?(user: user)
  end

  test 'completed? with correct submission after deadline within course' do
    series = create :series, activity_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Correct submission after deadline
    create :correct_submission,
           course: series.course,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline + 2.minutes)
    assert_equal true, series.completed?(user: user)
  end

  test 'completed? with correct submission after deadline without course' do
    series = create :series, activity_count: 1, deadline: Time.current
    user = create :user

    deadline = series.deadline
    # Correct submission after deadline
    create :correct_submission,
           exercise: series.exercises.first,
           user: user,
           created_at: (deadline + 2.minutes)
    assert_equal false, series.completed?(user: user)
  end
end
