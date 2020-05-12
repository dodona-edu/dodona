require 'test_helper'

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @series = create :series, exercise_count: 2, deadline: DateTime.now + 4.hours
    @exercises = @series.exercises
    @users = (0..2).map { |_| create :user }
    @users.each do |user|
      user.enrolled_courses << @series.course
      @exercises.each do |ex|
        create :submission, exercise: ex, user: user, course: @series.course, status: :correct
      end
    end
    @course_admin = create(:staff)
    @course_admin.administrating_courses << @series.course
    sign_in @course_admin
  end

  test 'Create session via wizard page' do
    post review_sessions_path, params: {
      review_session: {
        series_id: @series.id,
        deadline: DateTime.now + 4.days
      }
    }

    assert_response :redirect
    assert_equal @users.count * @exercises.count, @series.review_session.reviews.count
  end

  test "Can update a review's completed status" do
    post review_sessions_path, params: {
      review_session: {
        series_id: @series.id,
        deadline: DateTime.now + 4.days
      }
    }

    random_review = @series.review_session.reviews.sample
    assert_not_nil random_review

    patch review_session_review_path(@series.review_session, random_review), params: { review: { completed: true } }

    random_review.reload
    assert_equal true, random_review.completed, 'completed should have been set to true'

    patch review_session_review_path(@series.review_session, random_review), params: { review: { completed: true } }

    random_review.reload
    assert_equal true, random_review.completed, 'marking complete should be idempotent'

    patch review_session_review_path(@series.review_session, random_review), params: { review: { completed: false } }

    random_review.reload
    assert_equal false, random_review.completed, 'completed should have been set to false'
  end

  test 'Notifications should be made when a review is released' do
    post review_sessions_path, params: {
      review_session: { series_id: @series.id, deadline: DateTime.now + 4.days }
    }
    review_session = @series.review_session
    review_session.update(released: false)

    reviews = review_session.reviews.decided.includes(:submission)
    reviews.each do |review|
      # Annotation bound to Review
      review_session.annotations.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)

      # Normal annotation
      Annotation.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)
    end
    assert_equal reviews.count, Notification.all.count, 'only notifications for the annotations without a review session'

    review_session.reviews.each do |review|
      review.update(completed: true)
    end
    assert_equal reviews.count, Notification.all.count, 'no new notification should be made upon completing a review'

    review_session.update(released: true)

    assert_equal reviews.count + @users.count, Notification.all.count, 'A new notification per user should be made upon releasing a review session, along with keeping the notifications made for annotations without a review session'
  end

  test 'non released annotations are not queryable' do
    post review_sessions_path, params: {
      review_session: {
        series_id: @series.id,
        deadline: DateTime.now + 4.days
      }
    }
    review_session = @series.review_session
    review_session.update(released: false)

    reviews = review_session.reviews.decided.includes(:submission)
    reviews.each do |review|
      # Annotation bound to Review
      review_session.annotations.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)

      # Normal annotation
      Annotation.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)
    end

    student = @users.sample
    assert_not_nil student
    picked_submission = review_session.reviews.joins(:review_user).where(review_users: { user: student }).decided.sample.submission

    get submission_annotations_path(picked_submission, format: :json)
    json_response = JSON.parse(@response.body)
    assert_equal 2, json_response.size, 'Course admin should be able to see unreleased submissions'

    sign_in student

    assert_equal student, picked_submission.user
    get submission_annotations_path(picked_submission, format: :json)

    json_response = JSON.parse(@response.body)
    assert_equal 1, json_response.size, 'Only one annotation is visible here, since the review session is unreleased'

    review_session.update(released: true)

    get submission_annotations_path(picked_submission, format: :json)

    json_response = JSON.parse(@response.body)
    assert_equal 2, json_response.size, 'Both annotations are visible, as the review session is released'

    random_unauthorized_student = create :student
    sign_in random_unauthorized_student

    get submission_annotations_path(picked_submission, format: :json)

    json_response = JSON.parse(@response.body)
    assert_equal 0, json_response.size, 'Non authorized users can not query for annotations on a submission that is not their own'

    sign_out random_unauthorized_student

    get submission_annotations_path(picked_submission, format: :json)

    json_response = JSON.parse(@response.body)
    assert_equal 0, json_response.size, 'Non logged in users may not query the annotations of a submission'
  end

  test 'review page only available for course admins' do
    post review_sessions_path, params: {
      review_session: {
        series_id: @series.id,
        deadline: DateTime.now + 4.days
      }
    }
    review_session = @series.review_session
    random_review = review_session.reviews.decided.sample

    get review_session_review_path(review_session, random_review)

    assert_response :success

    sign_out @course_admin

    # No log in
    get review_session_review_path(review_session, random_review)
    assert_response :redirect # Redirect to sign in page

    random_user = @users.sample
    assert_not random_user.admin_of?(@series.course)

    sign_in random_user
    get review_session_review_path(review_session, random_review)
    assert_response :redirect # Redirect to sign in page
  end

  test 'When a review session gets deleted, all the annotations created should be unset & therefor released' do
    post review_sessions_path, params: {
      review_session: { series_id: @series.id,
                        deadline: DateTime.now + 4.days }
    }
    review_session = @series.review_session
    annotations = []
    review_session.reviews.decided.each do |review|
      annotations << review.submission.annotations.create(review_session: review_session, user: @course_admin, annotation_text: Faker::Lorem.sentences(number: 3), line_nr: 0)
    end

    assert_not_empty annotations
    review_session.destroy

    annotations.each do |annotation|
      annotation.reload
      assert_nil annotation.review_session

      get submission_annotations_path(annotation.submission, format: :json)
      json_response = JSON.parse(@response.body)
      assert_equal 1, json_response.size, 'The one annotation is visible here, since the review session is deleted'
    end
  end

  test 'When there is already a review session for this series, we should redirect to the ready made one when a user wants to create a new one' do
    post review_sessions_path, params: {
      review_session: { series_id: @series.id,
                        deadline: DateTime.now + 4.days }
    }

    review_session_count = ReviewSession.where(series: @series).count

    review_session = @series.review_session
    assert_not_nil review_session

    get new_review_session_path(series_id: @series.id)
    assert_response :redirect

    post review_sessions_path, params: {
      review_session: { series_id: @series,
                        deadline: DateTime.now + 4.days,
                        users: @users.map(&:id),
                        exercises: @exercises.map(&:id) }
    }
    assert_response :redirect

    assert_equal review_session_count, ReviewSession.where(series: @series).count, 'No new review sessions should be made for this series'

    sign_out @course_admin
    get new_review_session_path(series_id: @series.id)
    assert_response :redirect
  end

  test 'When there is no previous review session for this series, we can query the wizard' do
    get new_review_session_path(series_id: @series.id)
    assert_response :success

    sign_out @course_admin
    get new_review_session_path(series_id: @series.id)
    assert_response :redirect
  end

  test 'Edit page for a review session is only available for course admins' do
    post review_sessions_path, params: {
      review_session: {
        series_id: @series.id,
        deadline: DateTime.now + 4.days
      }
    }
    random_student = create :student
    review_session = @series.review_session
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    get edit_review_session_path(review_session)
    assert_response :success

    sign_out @course_admin
    get edit_review_session_path(review_session)
    assert_response :redirect

    sign_in random_student
    get edit_review_session_path(review_session)
    assert_response :redirect
    sign_out random_student

    assert_not_nil staff_member
    sign_in staff_member
    get edit_review_session_path(review_session)
    assert_response :success
  end

  test 'Review page should be available for a course admin, for each review with a submission' do
    post review_sessions_path, params: {
      review_session: {
        series_id: @series.id,
        deadline: DateTime.now + 4.days
      }
    }

    random_student = create :student
    student_from_review_session = @users.sample
    assert_not student_from_review_session.admin_of?(@series.course)
    review_session = @series.review_session
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    review_session.reviews.decided.each do |review|
      get review_session_review_path(review_session, review)
      assert_response :success
    end
    sign_out @course_admin

    sign_in staff_member
    review_session.reviews.decided.each do |review|
      get review_session_review_path(review_session, review)
      assert_response :success
    end
    sign_out staff_member

    sign_in random_student
    review_session.reviews.decided.each do |review|
      get review_session_review_path(review_session, review)
      assert_response :redirect
    end
    sign_out random_student

    sign_in student_from_review_session
    review_session.reviews.decided.each do |review|
      get review_session_review_path(review_session, review)
      assert_response :redirect
    end
    sign_out student_from_review_session

    review_session.reviews.decided.each do |review|
      get review_session_review_path(review_session, review)
      assert_response :redirect
    end
  end

  test 'Show page should only be available to zeus and course admins' do
    post review_sessions_path, params: {
      review_session: {
        series_id: @series.id,
        deadline: DateTime.now + 4.days
      }
    }

    review_session = @series.review_session
    random_student = create :student
    student_from_review_session = @users.sample
    assert_not student_from_review_session.admin_of?(@series.course)
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    [@course_admin, staff_member].each do |person|
      sign_in person
      get review_session_path(review_session)
      assert_response :success, 'Should get access since the user is not a student'
      sign_out person
    end

    [student_from_review_session, random_student].each do |person|
      sign_in person
      get review_session_path(review_session)
      assert_response :redirect, 'Should not get access since the user is a student'
      sign_out person
    end
  end
end
