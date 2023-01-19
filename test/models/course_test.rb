# == Schema Information
#
# Table name: courses
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  year              :string(255)
#  secret            :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  description       :text(4294967295)
#  visibility        :integer          default("visible_for_all")
#  registration      :integer          default("open_for_institutional_users")
#  teacher           :string(255)
#  institution_id    :bigint
#  search            :string(4096)
#  moderated         :boolean          default(FALSE), not null
#  enabled_questions :boolean          default(TRUE), not null
#  featured          :boolean          default(FALSE), not null
#

require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  test 'factory should create course' do
    course = create :course
    assert_not_nil course
    assert_not course.secret.blank?
  end

  test 'create course with emoji' do
    name = 'Programming 🧑‍💻'
    course = create :course, name: name
    assert_not_nil course
    assert_equal course.name, name
  end

  test 'course formatted year should not have spaces' do
    course = build :course, year: '2017 - 2018'
    assert_equal '2017–2018', course.formatted_year
  end

  test 'course formatted attribution should only have a dot with teacher and institution' do
    course = build :course, teacher: ''
    assert_equal '', course.formatted_attribution

    course = build :course, teacher: 'teach'
    assert_equal 'teach', course.formatted_attribution

    course = build :course, teacher: '', institution: (build :institution, short_name: 'sn', name: '')
    assert_equal '', course.formatted_attribution

    course = build :course, teacher: 'teach', institution: (build :institution, short_name: 'sn', name: '')
    assert_equal 'teach', course.formatted_attribution

    course = build :course, teacher: '', institution: (build :institution, short_name: 'sn', name: 'inst')
    assert_equal 'inst', course.formatted_attribution

    course = build :course, teacher: 'teach', institution: (build :institution, short_name: 'sn', name: 'inst')
    assert_equal 'teach · inst', course.formatted_attribution
  end

  test 'hidden course should always require secret' do
    course = build :course, institution: (build :institution), visibility: :hidden
    user1 = build :user, institution: nil
    user2 = build :user, institution: course.institution
    user3 = build :user, institution: (build :institution)

    assert course.secret_required?
    assert course.secret_required?(user1)
    assert course.secret_required?(user2)
    assert course.secret_required?(user3)
  end

  test 'visible_for_institution course should not require secret for user of institution' do
    course = build :course, institution: (build :institution), visibility: :visible_for_institution
    user1 = build :user, institution: nil
    user2 = build :user, institution: course.institution
    user3 = build :user, institution: (build :institution)

    assert course.secret_required?
    assert course.secret_required?(user1)
    assert_not course.secret_required?(user2)
    assert course.secret_required?(user3)
  end

  test 'visible_for_all course should never require secret' do
    course = build :course, institution: (build :institution), visibility: :visible_for_all
    user1 = build :user, institution: nil
    user2 = build :user, institution: course.institution
    user3 = build :user, institution: (build :institution)

    assert_not course.secret_required?
    assert_not course.secret_required?(user1)
    assert_not course.secret_required?(user2)
    assert_not course.secret_required?(user3)
  end

  test 'correct solutions should be updated for submission in course' do
    course = courses(:course1)
    series = create :series, course: course, activity_count: 1
    user = users(:student)

    assert_equal 0, course.correct_solutions

    create :wrong_submission,
           course: course,
           exercise: series.exercises[0],
           user: user

    assert_equal 0, course.correct_solutions

    create :correct_submission,
           course: course,
           exercise: series.exercises[0],
           user: user

    assert_equal 1, course.correct_solutions
  end

  test 'correct solutions should not be updated for submission outside course' do
    course = courses(:course1)
    series = create :series, course: course, activity_count: 1
    user = users(:student)

    assert_equal 0, course.correct_solutions

    create :wrong_submission,
           exercise: series.exercises[0],
           user: user

    assert_equal 0, course.correct_solutions

    create :correct_submission,
           exercise: series.exercises[0],
           user: user

    assert_equal 0, course.correct_solutions
  end

  test 'course scoresheet should be correct' do
    course = courses(:course1)
    create_list :series, 2,
                course: course,
                exercise_count: 2,
                deadline: Time.current
    content_pages = create_list :content_page, 2
    SeriesMembership.create(series: course.series.first, activity: content_pages.first)
    SeriesMembership.create(series: course.series.second, activity: content_pages.second)
    users = create_list(:user, 6, courses: [course])

    expected_started = Hash.new 0
    expected_accepted = Hash.new 0
    course.series.each do |series|
      deadline = series.deadline
      series.exercises.map do |exercise|
        6.times do |i|
          u = users[i]
          case i
          when 0 # Wrong submission before deadline
            create :wrong_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes),
                   course: course
            expected_started[[u.id, series.id]] += 1
          when 1 # Wrong, then correct submission before deadline
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 2.minutes),
                   course: course
            create :correct_submission,
                   exercise: exercise,
                   user: u,
                   created_at: (deadline - 1.minute),
                   course: course
            expected_started[[u.id, series.id]] += 1
            expected_accepted[[u.id, series.id]] += 1
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
      series.content_pages.map do |cp|
        6.times do |i|
          u = users[i]
          if i.even?
            create :activity_read_state, activity: cp, user: u, course: course, created_at: (deadline - 2.minutes)
            expected_started[[u.id, series.id]] += 1
            expected_accepted[[u.id, series.id]] += 1
          else
            create :activity_read_state, activity: cp, user: u, course: course, created_at: (deadline + 2.minutes)
          end
        end
      end
    end

    scoresheet = course.scoresheet
    # All users are included in the scoresheet.
    assert_equal users.to_set, scoresheet[:users].to_set
    # All series are included in the scoresheet.
    assert_equal course.series.to_set, scoresheet[:series].to_set
    # All series and users are counted.
    assert_equal course.series.count * users.count, scoresheet[:hash].count
    # Correct series are counted.
    assert_equal scoresheet[:hash].keys.pluck(1).to_set, scoresheet[:series].map(&:id).to_set
    # Correct users are counted.
    assert_equal scoresheet[:hash].keys.map(&:first).to_set, users.map(&:id).to_set
    # Counts are correct.
    scoresheet[:hash].each do |key, counts|
      assert_equal expected_accepted[key], counts[:accepted]
      assert_equal expected_started[key], counts[:started]
    end
  end

  test 'destroying course does not destroy submissions' do
    course = create :course, series_count: 1, exercises_per_series: 1, submissions_per_exercise: 1
    assert_difference 'Submission.count', 0 do
      assert course.destroy
    end
  end

  test 'destroying course should move submission files' do
    course = create :course, series_count: 1, exercises_per_series: 1, submissions_per_exercise: 1
    submission = Submission.first
    code = submission.code
    assert course.destroy
    assert_equal code, submission.reload.code
  end

  test 'all_activities_accessible? should be correct' do
    course = create :course, series_count: 1, exercises_per_series: 0
    ex = create :exercise, access: :public
    course.series.first.exercises << ex
    assert course.all_activities_accessible?
    ex.update(access: :private)
    assert_not course.all_activities_accessible?
    course.usable_repositories << ex.repository
    assert course.all_activities_accessible?
  end

  test 'can_register scope should always contain own courses' do
    i = create :institution
    [create(:institution), i, nil].each do |institution|
      u = create :user, institution: institution
      CourseMembership.statuses.each do |s|
        Course.registrations.each do |r|
          c = create :course, registration: r[1], institution: i
          CourseMembership.create user: u, course: c, status: s[1]
        end
      end
      assert_equal u.subscribed_courses.count, u.subscribed_courses.can_register(u).count
    end
  end

  test 'can_register should only return course if the user can register for it' do
    i = create :institution
    Course.registrations.each do |r|
      create :course, registration: r[1], institution: i
    end
    [create(:institution), i, nil].each do |institution|
      u = create :user, institution: institution
      Course.all.each do |c|
        assert_equal c.open_for_user?(u), Course.can_register(u).exists?(c.id)
      end
    end
  end

  test 'Activity count returns number of activities in vissible series' do
    course = create :course, series_count: 2, exercises_per_series: 1, content_pages_per_series: 1
    course.series.first.update(visibility: :hidden)
    assert_equal 2, course.activity_count

    course.series.first.update(visibility: :closed)
    assert_equal 2, course.activity_count

    course.series.last.update(visibility: :hidden)
    assert_equal 0, course.activity_count

    course.series.first.update(visibility: :open)
    course.series.last.update(visibility: :open)
    assert_equal 4, course.activity_count
  end

  test 'Completed activity count returns number of completed activities by the user in vissible series' do
    course = create :course, series_count: 2, exercises_per_series: 1, content_pages_per_series: 1
    course.series.first.update(visibility: :open)
    course.series.last.update(visibility: :hidden)

    user = create :user
    CourseMembership.create user: user, course: course, status: :student
    assert_equal 0, course.completed_activity_count(user)

    # Don't count outside course
    create :correct_submission, user: user, exercise: course.series.first.exercises.first
    assert_equal 0, course.completed_activity_count(user)
    # Don't count wrong submission
    create :wrong_submission, user: user, exercise: course.series.first.exercises.first, course: course
    assert_equal 0, course.completed_activity_count(user)
    create :correct_submission, user: user, exercise: course.series.first.exercises.first, course: course
    assert_equal 1, course.completed_activity_count(user)
    create :activity_read_state, user: user, activity: course.series.first.content_pages.first, course: course
    assert_equal 2, course.completed_activity_count(user)

    # dont count in non visible series
    create :activity_read_state, user: user, activity: course.series.last.content_pages.first, course: course
    assert_equal 2, course.completed_activity_count(user)

    course.series.last.update(visibility: :open)
    assert_equal 3, course.completed_activity_count(user)

    # dont count in closed series
    course.series.first.update(visibility: :closed)
    assert_equal 1, course.completed_activity_count(user)
  end

  test 'Start activity count returns number of started activities by the user in vissible series' do
    course = create :course, series_count: 2, exercises_per_series: 1, content_pages_per_series: 1
    course.series.first.update(visibility: :open)
    course.series.last.update(visibility: :hidden)

    user = create :user
    CourseMembership.create user: user, course: course, status: :student
    assert_equal 0, course.started_activity_count(user)

    # Don't count outside course
    create :correct_submission, user: user, exercise: course.series.first.exercises.first
    assert_equal 0, course.started_activity_count(user)
    # Count wrong submission
    create :wrong_submission, user: user, exercise: course.series.first.exercises.first, course: course
    assert_equal 1, course.started_activity_count(user)
    create :correct_submission, user: user, exercise: course.series.first.exercises.first, course: course
    assert_equal 1, course.started_activity_count(user)
    create :activity_read_state, user: user, activity: course.series.first.content_pages.first, course: course
    assert_equal 2, course.started_activity_count(user)

    # dont count in non visible series
    create :activity_read_state, user: user, activity: course.series.last.content_pages.first, course: course
    assert_equal 2, course.started_activity_count(user)

    course.series.last.update(visibility: :open)
    assert_equal 3, course.started_activity_count(user)

    # dont count in closed series
    course.series.first.update(visibility: :closed)
    assert_equal 1, course.started_activity_count(user)
  end

  test 'Home page activities should return the activity with the latest submission in a visible series and subsequent activities' do
    course = create :course, series_count: 5, exercises_per_series: 1, content_pages_per_series: 1
    course.series.first.update(visibility: :open)
    course.series.last.update(visibility: :hidden)

    user = create :user
    CourseMembership.create user: user, course: course, status: :student

    # Should start from first activity when no submissions
    result = course.homepage_activities(user, 3)
    assert_equal 3, result.count
    assert_equal course.series.first.activities.first, result.first[:activity]
    assert_equal course.series.first, result.first[:series]
    assert_nil result.first[:submission]

    assert_equal course.series.first.activities.second, result.second[:activity]
    assert_equal course.series.first, result.second[:series]
    assert_nil result.second[:submission]

    assert_equal course.series.second.activities.first, result.third[:activity]
    assert_equal course.series.second, result.third[:series]
    assert_nil result.third[:submission]

    # Should start from after last submission if submission was correct
    create :correct_submission, user: user, exercise: course.series.second.exercises.first, course: course
    result = course.homepage_activities(user, 3)
    assert_equal 3, result.count
    assert_equal course.series.second.activities.second, result.first[:activity]
    assert_equal course.series.second, result.first[:series]
    assert_nil result.first[:submission]

    assert_equal course.series.third.activities.first, result.second[:activity]
    assert_equal course.series.third, result.second[:series]
    assert_nil result.second[:submission]

    assert_equal course.series.third.activities.second, result.third[:activity]
    assert_equal course.series.third, result.third[:series]
    assert_nil result.third[:submission]

    # should only return limit number of activities
    result = course.homepage_activities(user, 1)
    assert_equal 1, result.count
    assert_equal course.series.second.activities.second, result.first[:activity]
    assert_equal course.series.second, result.first[:series]
    assert_nil result.first[:submission]

    # should start from last submission if submission was wrong
    w1 = create :wrong_submission, user: user, exercise: course.series.third.exercises.first, course: course
    result = course.homepage_activities(user, 3)
    assert_equal 3, result.count
    assert_equal course.series.third.activities.first, result.first[:activity]
    assert_equal course.series.third, result.first[:series]
    assert_equal w1, result.first[:submission]

    assert_equal course.series.third.activities.second, result.second[:activity]
    assert_equal course.series.third, result.second[:series]
    assert_nil result.second[:submission]

    assert_equal course.series.fourth.activities.first, result.third[:activity]
    assert_equal course.series.fourth, result.third[:series]
    assert_nil result.third[:submission]

    # should skip completed activities
    create :activity_read_state, user: user, activity: course.series.third.content_pages.first, course: course
    create :activity_read_state, user: user, activity: course.series.first.content_pages.first, course: course
    create :correct_submission, user: user, exercise: course.series.first.exercises.first, course: course
    result = course.homepage_activities(user, 3)
    assert_equal 3, result.count
    assert_equal course.series.second.activities.second, result.first[:activity]
    assert_equal course.series.second, result.first[:series]
    assert_nil result.first[:submission]

    assert_equal course.series.third.activities.first, result.second[:activity]
    assert_equal course.series.third, result.second[:series]
    assert_equal w1, result.second[:submission]

    assert_equal course.series.fourth.activities.first, result.third[:activity]
    assert_equal course.series.fourth, result.third[:series]
    assert_nil result.third[:submission]

    # should skip activities in hidden series
    course.series.second.update(visibility: :hidden)
    result = course.homepage_activities(user, 3)
    assert_equal 3, result.count
    assert_equal course.series.third.activities.first, result.first[:activity]
    assert_equal course.series.third, result.first[:series]
    assert_equal w1, result.first[:submission]

    assert_equal course.series.fourth.activities.first, result.second[:activity]
    assert_equal course.series.fourth, result.second[:series]
    assert_nil result.second[:submission]

    assert_equal course.series.fourth.activities.second, result.third[:activity]
    assert_equal course.series.fourth, result.third[:series]
    assert_nil result.third[:submission]

    # should start from first activity if end is reached
    w2 = create :wrong_submission, user: user, exercise: course.series.fourth.exercises.first, course: course
    result = course.homepage_activities(user, 3)
    assert_equal 3, result.count
    assert_equal course.series.fourth.activities.first, result.first[:activity]
    assert_equal course.series.fourth, result.first[:series]
    assert_equal w2, result.first[:submission]

    assert_equal course.series.fourth.activities.second, result.second[:activity]
    assert_equal course.series.fourth, result.second[:series]
    assert_nil result.second[:submission]

    assert_equal course.series.third.activities.first, result.third[:activity]
    assert_equal course.series.third, result.third[:series]
    assert_equal w1, result.third[:submission]

    # should return less activities if limit can't be reached
    create :activity_read_state, user: user, activity: course.series.fourth.content_pages.first, course: course
    result = course.homepage_activities(user, 3)
    assert_equal 2, result.count
    assert_equal course.series.fourth.activities.first, result.first[:activity]
    assert_equal course.series.fourth, result.first[:series]
    assert_equal w2, result.first[:submission]

    assert_equal course.series.third.activities.first, result.second[:activity]
    assert_equal course.series.third, result.second[:series]
    assert_equal w1, result.second[:submission]
  end

  test 'Series being worked on should return the series most students are working on' do
    course = create :course, series_count: 5, exercises_per_series: 2
    5.times { course.enrolled_members << create(:user) }

    # no activity should default to first series
    assert_equal course.series.first, course.series_being_worked_on.first
    assert_equal course.series.second, course.series_being_worked_on.second

    # should return series with most users with recent activity
    # should be ignored because not most recent for user
    create :submission, user: course.enrolled_members.first, exercise: course.series.third.exercises.first, course: course
    # should be counted
    create :submission, user: course.enrolled_members.first, exercise: course.series.third.exercises.second, course: course
    # should be ignored because not most recent for user
    create :submission, user: course.enrolled_members.second, exercise: course.series.third.exercises.first, course: course
    # should be counted
    create :submission, user: course.enrolled_members.second, exercise: course.series.fourth.exercises.first, course: course
    # should be counted
    create :submission, user: course.enrolled_members.third, exercise: course.series.fourth.exercises.second, course: course

    assert_equal course.series.fourth, course.series_being_worked_on.first
    assert_equal course.series.third, course.series_being_worked_on.second
    assert_equal course.series.first, course.series_being_worked_on.third

    # should exclude all submissions from first series to calculate second series
    create :submission, user: course.enrolled_members.second, exercise: course.series.second.exercises.first, course: course
    create :submission, user: course.enrolled_members.third, exercise: course.series.second.exercises.first, course: course

    assert_equal course.series.second, course.series_being_worked_on.first
    assert_equal course.series.fourth, course.series_being_worked_on.second
    assert_equal course.series.third, course.series_being_worked_on.third

    # should be able to manually exclude series
    assert_equal course.series.fourth, course.series_being_worked_on(3, [course.series.second]).first
    assert_equal course.series.third, course.series_being_worked_on(3, [course.series.second]).second
    assert_equal course.series.first, course.series_being_worked_on(3, [course.series.second]).third

    # should be able to limit number of series
    assert_equal 3, course.series_being_worked_on.count
    assert_equal 2, course.series_being_worked_on(2).count
    assert_equal 5, course.series_being_worked_on(7).count

    # can never return excluded series
    assert_equal 4, course.series_being_worked_on(7, [course.series.first]).count
    assert_not_includes course.series_being_worked_on(7, [course.series.first]), course.series.first
  end

  test 'home page admin notifications should return nothing if no admin' do
    course = create :course
    assert_nil course.homepage_admin_notifications
  end

  test 'home page admin notifications should contain notifications' do
    course = create :course, series_count: 2, exercises_per_series: 2
    3.times { course.enrolled_members << create(:user) }
    staff = create :staff
    CourseMembership.create(user: staff, course: course, status: :course_admin)
    Current.user = staff
    assert_empty course.homepage_admin_notifications

    # open questions
    s = create :correct_submission, course: course, exercise: course.series.first.exercises.first, user: course.enrolled_members.first, created_at: DateTime.now - 1.hour
    q = create :question, submission: s
    assert_equal 1, course.homepage_admin_notifications.count

    q.question_state = :answered
    q.save
    assert_empty course.homepage_admin_notifications

    3.times do
      s = create :correct_submission, course: course, exercise: course.series.first.exercises.first, user: course.enrolled_members.sample, created_at: DateTime.now - 1.hour
      create :question, submission: s
    end
    assert_equal 1, course.homepage_admin_notifications.count

    # pending users
    course.pending_members << create(:user)
    assert_equal 2, course.homepage_admin_notifications.count

    course.course_memberships.where(status: :pending).first.update(status: :student)
    assert_equal 1, course.homepage_admin_notifications.count

    3.times { course.pending_members << create(:user) }
    assert_equal 2, course.homepage_admin_notifications.count

    # Incomplete feedbacks
    e = create :evaluation, series: course.series.first
    assert_equal 3, course.homepage_admin_notifications.count

    e.feedbacks.each do |f|
      f.update(completed: true)
      f.save
    end
    assert_equal 2, course.homepage_admin_notifications.count
  end

  test 'students should not see non visible homepage series' do
    course = create :course, series_count: 2, exercises_per_series: 2
    assert_equal 0, course.homepage_series.count
    course.series.first.update(deadline: DateTime.now + 1.hour)
    assert_equal 1, course.homepage_series.count
    course.series.first.update(visibility: :hidden)
    assert_equal 0, course.homepage_series.count
    Current.user = create :student
    assert_equal 0, course.homepage_series.count
    Current.user = create :staff
    assert_equal 0, course.homepage_series.count
    Current.user = create :zeus
    assert_equal 0, course.homepage_series.count

    teacher = create :staff
    CourseMembership.create(user: teacher, course: course, status: :course_admin)
    assert_equal 0, course.homepage_series.count

    Current.user = teacher
    assert_equal 1, course.homepage_series.count

  end
end
