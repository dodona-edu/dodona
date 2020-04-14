require 'test_helper'

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @series = create :series, :with_submissions, deadline: DateTime.now + 4.hours
    @users = User.joins(:submissions).where(submissions: @series.exercises.joins(:submissions)).uniq
    @exercises = @series.exercises
    @users.each do |user|
      user.submissions.each do |submission|
        submission.status = :correct
        submission.save
      end
    end
    @zeus = create(:zeus)
    sign_in @zeus
  end

  test 'Create session via wizard page' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    assert_response :redirect
    assert_equal @users.count * @exercises.count, @series.review_session.reviews.count
  end

  test 'Not all users' do
    users = [@users.first.id]
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: users,
        exercises: @exercises.map(&:id)
      }
    }

    assert_response :redirect
    assert_equal 1 * @exercises.count, @series.review_session.reviews.count
  end

  test 'Not all exercises' do
    exercises_take_map = @exercises.take(2).map(&:id)
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: exercises_take_map
      }
    }

    assert_response :redirect
    assert_equal 2 * @users.count, @series.review_session.reviews.count
  end

  test 'Not all exercises & users' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: [@users.first.id],
        exercises: @exercises.take(2).map(&:id)
      }
    }

    assert_response :redirect
    assert_equal 2, @series.review_session.reviews.count
  end

  test 'Update series with reduced user count' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    patch review_session_path(@series.review_session), params: {
      review_session: {
        users: @users.take(1).map(&:id)
      }
    }

    assert_equal @exercises.count * 1, @series.review_session.reviews.count
  end

  test 'Update series with reduced exercise count' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    patch review_session_path(@series.review_session), params: {
      review_session: {
        exercises: @exercises.take(2).map(&:id)
      }
    }

    assert_equal @users.count * 2, @series.review_session.reviews.count
  end

  test 'Update series with reduced exercise count and user count' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    assert_equal @users.count * @exercises.count, @series.review_session.reviews.count

    patch review_session_path(@series.review_session), params: {
      review_session: {
        exercises: @exercises.take(2).map(&:id),
        users: @users.take(1).map(&:id)
      }
    }

    assert_equal 2, @series.review_session.reviews.count
  end

  test 'Update series with adding users, before adding them back' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    assert_equal @users.count * @exercises.count, @series.review_session.reviews.count

    patch review_session_path(@series.review_session), params: {
      review_session: {
        released: false,
        exercises: @exercises.take(2).map(&:id),
        users: @users.take(1).map(&:id)
      }
    }

    assert_equal 2, @series.review_session.reviews.count

    patch review_session_path(@series.review_session), params: {
      review_session: {
        released: false,
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    assert_equal @users.count * @exercises.count, @series.review_session.reviews.count
  end

  test "Can update a review's completed status" do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    random_review = @series.review_session.reviews.sample
    assert_not_nil random_review

    post review_complete_review_session_path(@series.review_session, random_review), params: {
      review: {
        status: true
      }
    }

    refetched = @series.review_session.reviews.find(random_review.id)
    assert_equal true, refetched.completed, 'completed should have been set to true'

    post review_complete_review_session_path(@series.review_session, random_review), params: {
      review: {
        status: true
      }
    }

    refetched = @series.review_session.reviews.find(random_review.id)
    assert_equal true, refetched.completed, 'marking complete should be idempotent'

    post review_complete_review_session_path(@series.review_session, random_review), params: {
      review: {
        status: false
      }
    }

    refetched = @series.review_session.reviews.find(random_review.id)
    assert_equal false, refetched.completed, 'completed should have been set to false'
  end

  test 'Notifications should be made when a review is released' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    review_session = @series.review_session
    review_session.released = false
    review_session.save

    reviews = review_session.reviews.decided.includes(:submission)
    reviews.each do |review|
      # Annotation bound to Review
      review_session.annotations.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @zeus)

      # Normal annotation
      Annotation.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @zeus)
    end
    assert_equal reviews.count, Notification.all.count, 'only notifications for the annotations without a review session'

    review_session.reviews.each do |review|
      review.completed = true
      review.save
    end
    assert_equal reviews.count, Notification.all.count, 'no new notification should be made upon completing a review'

    review_session.released = true
    review_session.save

    assert_equal reviews.count + @users.count, Notification.all.count, 'A new notification per user should be made upon releasing a review session, a long with keeping the notifications made for annotations without a review session'
  end

  test 'non released annotations are not queryable' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    review_session = @series.review_session
    review_session.released = false
    review_session.save

    reviews = review_session.reviews.decided.includes(:submission)
    reviews.each do |review|
      # Annotation bound to Review
      review_session.annotations.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @zeus)

      # Normal annotation
      Annotation.create(submission: review.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @zeus)
    end

    student = @users.sample
    assert_not_nil student

    sign_in student

    picked_submission = review_session.reviews.where(user: student).decided.sample.submission
    assert_not_nil picked_submission
    assert_equal student, picked_submission.user
    get submission_annotations_path(picked_submission), headers: { accept: 'application/json' }

    json_response = JSON.parse(@response.body)
    assert_equal 1, json_response.size, 'Only one annotation is visible here, since the review session is unreleased'

    review_session.released = true
    review_session.save

    get submission_annotations_path(picked_submission), headers: { accept: 'application/json' }

    json_response = JSON.parse(@response.body)
    assert_equal 2, json_response.size, 'Both annotations are visible, as the review session is released'

    random_unauthorized_student = create :student
    sign_in random_unauthorized_student

    get submission_annotations_path(picked_submission), headers: { accept: 'application/json' }

    json_response = JSON.parse(@response.body)
    assert_equal 0, json_response.size, 'Non authorized users can not query for annotations on a submission that is not their own'

    sign_out @zeus
    sign_out student
    sign_out random_unauthorized_student

    get submission_annotations_path(picked_submission), headers: { accept: 'application/json' }

    json_response = JSON.parse(@response.body)
    assert_equal 0, json_response.size, 'Non logged in users may not query the annotations of a submission'
  end

  test 'review page only available for course admins' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    review_session = @series.review_session
    random_review = review_session.reviews.decided.sample

    get review_review_session_path(review_session, random_review)

    assert_response :success

    sign_out @zeus

    # No log in
    get review_review_session_path(review_session, random_review)
    assert_response :redirect # Redirect to sign in page

    random_user = @users.sample
    assert_not random_user.admin_of?(@series.course)

    sign_in random_user
    get review_review_session_path(review_session, random_review)
    assert_response :redirect # Redirect to sign in page
  end

  test 'When a review session gets deleted, all the annotations created should be unset & therefor released' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    review_session = @series.review_session
    annotations = []
    review_session.reviews.decided.each do |review|
      annotations << review.submission.annotations.create(review_session: @review_session, user: @zeus, annotation_text: Faker::Lorem.sentences(number: 3), line_nr: 0)
    end

    assert_not_empty annotations
    review_session.destroy

    annotations.each do |annotation|
      assert_nil annotation.review_session

      get submission_annotations_path(annotation.submission, format: :json)
      json_response = JSON.parse(@response.body)
      assert_equal 1, json_response.size, 'The one annotation is visible here, since the review session is deleted'
    end
  end

  test 'When there is already a review session for this series, we should redirect to the ready made one when a user wants to create a new one' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    review_session_count = ReviewSession.where(series: @series).count

    review_session = @series.review_session
    assert_not_nil review_session

    get review_series_path(@series)
    assert_response :redirect

    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    assert_response :redirect

    assert_equal review_session_count, ReviewSession.where(series: @series).count, 'No new review sessions should be made for this series'

    sign_out @zeus
    get review_series_path(@series)
    assert_response :redirect
  end

  test 'When there is no previous review session for this series, we can query the wizard' do
    get review_series_path(@series)
    assert_response :success

    sign_out @zeus
    get review_series_path(@series)
    assert_response :redirect
  end

  test 'The overview page is only available for users that have a review in this review session' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    random_student = create :student

    review_session = @series.review_session
    review_session.reviews.each do |review|
      review&.submission&.annotations&.create(line_nr: 0, annotation_text: Faker::Lorem.sentences(number: 3), user: @zeus, review_session: review_session)
      review&.submission&.annotations&.create(line_nr: 0, annotation_text: Faker::Lorem.sentences(number: 3), user: @zeus, review_session: review_session)

      review.completed = true
      review.save
    end

    review_session.released = true
    review_session.save

    # Logged in as Zeus, should only have access if Zeus himself has a review
    get overview_review_session_path(review_session)
    if @users.include? @zeus
      assert_response :success
    else
      assert_response :redirect
    end

    # Not logged in, no access
    sign_out @zeus
    get overview_review_session_path(review_session)
    assert_response :redirect

    # Random student not in the users list (and as such not in the review session)
    sign_in random_student
    assert_not @users.include? random_student
    get overview_review_session_path(review_session)
    assert_response :redirect
  end

  test 'Edit page for a review session is only available for course admins' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }
    random_student = create :student
    review_session = @series.review_session
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    get edit_review_session_path(review_session)
    assert_response :success

    sign_out @zeus
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
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    random_student = create :student
    student_from_review_session = @users.sample
    assert_not student_from_review_session.admin_of?(@series.course)
    review_session = @series.review_session
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    review_session.reviews.decided.each do |review|
      get review_review_session_path(review_session, review)
      assert_response :success
    end
    sign_out @zeus

    sign_in staff_member
    review_session.reviews.decided.each do |review|
      get review_review_session_path(review_session, review)
      assert_response :success
    end
    sign_out staff_member

    sign_in random_student
    review_session.reviews.decided.each do |review|
      get review_review_session_path(review_session, review)
      assert_response :redirect
    end
    sign_out random_student

    sign_in student_from_review_session
    review_session.reviews.decided.each do |review|
      get review_review_session_path(review_session, review)
      assert_response :redirect
    end
    sign_out student_from_review_session

    review_session.reviews.decided.each do |review|
      get review_review_session_path(review_session, review)
      assert_response :redirect
    end
  end

  test 'Overview page should only be available when a session is released and to the correct people' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    random_student = create :student
    student_from_review_session = @users.sample
    assert_not student_from_review_session.admin_of?(@series.course)
    review_session = @series.review_session
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    assert_not review_session.released

    sign_out @zeus
    [@zeus, staff_member, student_from_review_session, random_student].each do |person|
      sign_in person
      get overview_review_session_path(review_session)
      assert_response :redirect, 'Should not get access since the review is unreleased'
      sign_out person
    end

    review_session.released = true
    review_session.save

    [@zeus, staff_member].each do |person|
      sign_in person
      get overview_review_session_path(review_session)
      if @users.include? person
        assert_response :success, "Should get access since the review is released and #{person.full_name} is part of the reviewees"
      else
        assert_response :redirect, "Should not get access since #{person.full_name} is not part of the reviewees group"
      end
      sign_out person
    end

    assert (@users.include? student_from_review_session), 'Student should be part of the users in the review session'
    sign_in student_from_review_session
    get overview_review_session_path(review_session)
    assert_response :success, 'Should get access since the review is released and the student is part of the reviewees'
    sign_out student_from_review_session

    assert_not (@users.include? random_student), 'this test is invalid if the random student is part of the reviewees'
    sign_in random_student
    get overview_review_session_path(review_session)
    assert_response :redirect, 'Should not get access since the student is not part of the reviewees'
  end

  test 'Show page should only be available to zeus and course admins' do
    post review_create_series_path(@series), params: {
      review_session: {
        deadline: DateTime.now + 4.days,
        users: @users.map(&:id),
        exercises: @exercises.map(&:id)
      }
    }

    review_session = @series.review_session
    random_student = create :student
    student_from_review_session = @users.sample
    assert_not student_from_review_session.admin_of?(@series.course)
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    [@zeus, staff_member].each do |person|
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
