require 'test_helper'

class PagesHelperTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include PagesHelper

  test 'home page admin notifications should contain notifications' do
    course = create :course, series_count: 2, exercises_per_series: 2
    3.times { course.enrolled_members << create(:user) }
    staff = create :staff
    CourseMembership.create(user: staff, course: course, status: :course_admin)
    Current.user = staff

    assert_empty homepage_course_admin_notifications(course)

    # open questions
    s = create :correct_submission, course: course, exercise: course.series.first.exercises.first, user: course.enrolled_members.first, created_at: DateTime.now - 1.hour
    q = create :question, submission: s

    assert_equal 1, homepage_course_admin_notifications(course).count

    q.question_state = :answered
    q.save

    assert_empty homepage_course_admin_notifications(course)

    3.times do
      s = create :correct_submission, course: course, exercise: course.series.first.exercises.first, user: course.enrolled_members.sample, created_at: DateTime.now - 1.hour
      create :question, submission: s
    end

    assert_equal 1, homepage_course_admin_notifications(course).count

    # pending users
    course.pending_members << create(:user)

    assert_equal 2, homepage_course_admin_notifications(course).count

    course.course_memberships.where(status: :pending).first.update(status: :student)

    assert_equal 1, homepage_course_admin_notifications(course).count

    3.times { course.pending_members << create(:user) }

    assert_equal 2, homepage_course_admin_notifications(course).count

    # Incomplete feedbacks
    e = create :evaluation, series: course.series.first

    assert_equal 3, homepage_course_admin_notifications(course).count

    e.feedbacks.each do |f|
      f.update(completed: true)
      f.save
    end

    assert_equal 2, homepage_course_admin_notifications(course).count

    # released evaluation
    e.feedbacks.first.update(completed: false)

    assert_equal 3, homepage_course_admin_notifications(course).count
    e.update(released: true)

    assert_equal 2, homepage_course_admin_notifications(course).count
  end
end
