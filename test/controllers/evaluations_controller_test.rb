require 'test_helper'

class EvaluationsControllerTest < ActionDispatch::IntegrationTest
  include EvaluationHelper

  def setup
    @series = create :series, exercise_count: 2, deadline: DateTime.now + 4.hours
    @exercises = @series.exercises
    @submitted_users = (0..2).map { |_| create :user }
    @submitted_users.each do |user|
      user.enrolled_courses << @series.course
      @exercises.each do |ex|
        create :submission, exercise: ex, user: user, course: @series.course, status: :correct, created_at: Time.current - 1.hour
      end
    end
    @no_submission_user = create :user
    @no_submission_user.enrolled_courses << @series.course
    @users = @submitted_users + [@no_submission_user]
    @course_admin = create(:staff)
    @course_admin.administrating_courses << @series.course
    sign_in @course_admin
  end

  test 'Create session via wizard page' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    @series.evaluation.update(users: @users)

    assert_response :redirect
    assert_equal @users.count * @exercises.count, @series.evaluation.feedbacks.count
  end

  test 'Can remove user from feedback' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    @series.evaluation.update(users: @users)

    assert_response :redirect
    assert_equal @users.count * @exercises.count, @series.evaluation.feedbacks.count

    post remove_user_evaluation_path(@series.evaluation, user_id: @users.first.id, format: :js)
    assert_equal (@users.count - 1) * @exercises.count, @series.evaluation.feedbacks.count
  end

  test 'Can add user to feedback' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    @series.evaluation.update(users: @users)

    assert_response :redirect
    assert_equal @users.count * @exercises.count, @series.evaluation.feedbacks.count

    user = create :user
    user.enrolled_courses << @series.course

    post add_user_evaluation_path(@series.evaluation, user_id: user.id, format: :js)
    assert_equal (@users.count + 1) * @exercises.count, @series.evaluation.feedbacks.count
  end

  test "Can update a feedback's completed status" do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    @series.evaluation.update(users: @series.course.enrolled_members)

    random_feedback = @series.evaluation.feedbacks.sample
    assert_not_nil random_feedback

    patch evaluation_feedback_path(@series.evaluation, random_feedback), params: { feedback: { completed: true } }

    random_feedback.reload
    assert_equal true, random_feedback.completed, 'completed should have been set to true'

    patch evaluation_feedback_path(@series.evaluation, random_feedback), params: { feedback: { completed: true } }

    random_feedback.reload
    assert_equal true, random_feedback.completed, 'marking complete should be idempotent'

    patch evaluation_feedback_path(@series.evaluation, random_feedback), params: { feedback: { completed: false } }

    random_feedback.reload
    assert_equal false, random_feedback.completed, 'completed should have been set to false'
  end

  test 'Notifications should be made when a feedback is released' do
    post evaluations_path, params: {
      evaluation: { series_id: @series.id, deadline: DateTime.now }
    }
    evaluation = @series.evaluation
    evaluation.update(users: @series.course.enrolled_members)
    evaluation.update(released: false)

    feedbacks = evaluation.feedbacks.includes(:submission)
    feedback_annotations = 0
    normal_annotations = 0
    feedbacks.each do |feedback|
      next if feedback.submission.nil?

      # Annotation bound to Feedback
      evaluation.annotations.create(submission: feedback.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)
      feedback_annotations += 1

      # Normal annotation
      Annotation.create(submission: feedback.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)
      normal_annotations += 1
    end
    assert_equal normal_annotations, Notification.all.count, 'only notifications for the annotations without a feedback session'

    evaluation.feedbacks.each do |feedback|
      feedback.update(completed: true)
    end
    assert_equal normal_annotations, Notification.all.count, 'no new notification should be made upon completing a feedback'

    evaluation.update(released: true)

    assert_equal normal_annotations + @users.count, Notification.all.count, 'A new notification per user should be made upon releasing a feedback session, along with keeping the notifications made for annotations without a feedback session'
  end

  test 'non released annotations are not queryable' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    evaluation = @series.evaluation
    evaluation.update(users: @series.course.enrolled_members)
    evaluation.update(released: false)

    feedbacks = evaluation.feedbacks.decided.includes(:submission)
    feedbacks.each do |feedback|
      # Annotation bound to Feedback
      evaluation.annotations.create(submission: feedback.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)

      # Normal annotation
      Annotation.create(submission: feedback.submission, annotation_text: Faker::Lorem.sentences(number: 2), line_nr: 0, user: @course_admin)
    end

    student = @submitted_users.sample
    assert_not_nil student
    picked_submission = evaluation.feedbacks.joins(:evaluation_user).where(evaluation_users: { user: student }).decided.sample.submission

    get submission_annotations_path(picked_submission, format: :json)
    json_response = JSON.parse(@response.body)
    assert_equal 2, json_response.size, 'Course admin should be able to see unreleased submissions'

    sign_in student

    assert_equal student, picked_submission.user
    get submission_annotations_path(picked_submission, format: :json)

    json_response = JSON.parse(@response.body)
    assert_equal 1, json_response.size, 'Only one annotation is visible here, since the feedback session is unreleased'

    evaluation.update(released: true)

    get submission_annotations_path(picked_submission, format: :json)

    json_response = JSON.parse(@response.body)
    assert_equal 2, json_response.size, 'Both annotations are visible, as the feedback session is released'

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

  test 'feedback page only available for course admins' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    evaluation = @series.evaluation
    evaluation.update(users: @series.course.enrolled_members)
    random_feedback = evaluation.feedbacks.decided.sample

    get evaluation_feedback_path(evaluation, random_feedback)

    assert_response :success

    sign_out @course_admin

    # No log in
    get evaluation_feedback_path(evaluation, random_feedback)
    assert_response :redirect # Redirect to sign in page

    random_user = @users.sample
    assert_not random_user.admin_of?(@series.course)

    sign_in random_user
    get evaluation_feedback_path(evaluation, random_feedback)
    assert_response :redirect # Redirect to sign in page
  end

  test 'feedback page should work even when there are no submissions' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    evaluation = @series.evaluation
    evaluation.update(users: @series.course.enrolled_members)
    feedback = evaluation.feedbacks.where(submission_id: nil).sample
    assert_not_nil feedback, 'should have feedback without submission'

    get evaluation_feedback_path(evaluation, feedback)
    assert_response :success
  end

  test 'When there is already a feedback session for this series, we should redirect to the ready made one when a user wants to create a new one' do
    post evaluations_path, params: {
      evaluation: { series_id: @series.id,
                    deadline: DateTime.now }
    }

    evaluation_count = Evaluation.where(series: @series).count

    evaluation = @series.evaluation
    assert_not_nil evaluation

    get new_evaluation_path(series_id: @series.id)
    assert_response :redirect

    post evaluations_path, params: {
      evaluation: { series_id: @series,
                    deadline: DateTime.now,
                    users: @users.map(&:id),
                    exercises: @exercises.map(&:id) }
    }
    assert_response :redirect

    assert_equal evaluation_count, Evaluation.where(series: @series).count, 'No new feedback sessions should be made for this series'

    sign_out @course_admin
    get new_evaluation_path(series_id: @series.id)
    assert_response :redirect
  end

  test 'When there is no previous feedback session for this series, we can query the wizard' do
    get new_evaluation_path(series_id: @series.id)
    assert_response :success

    sign_out @course_admin
    get new_evaluation_path(series_id: @series.id)
    assert_response :redirect
  end

  test 'Edit page for a feedback session is only available for course admins' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    random_student = create :student
    evaluation = @series.evaluation
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    get edit_evaluation_path(evaluation)
    assert_response :success

    sign_out @course_admin
    get edit_evaluation_path(evaluation)
    assert_response :redirect

    sign_in random_student
    get edit_evaluation_path(evaluation)
    assert_response :redirect
    sign_out random_student

    assert_not_nil staff_member
    sign_in staff_member
    get edit_evaluation_path(evaluation)
    assert_response :success
  end

  test 'Feedback page should be available for a course admin, for each feedback with a submission' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }

    random_student = create :student
    student_from_evaluation = @users.sample
    assert_not student_from_evaluation.admin_of?(@series.course)
    evaluation = @series.evaluation
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    evaluation.feedbacks.decided.each do |feedback|
      get evaluation_feedback_path(evaluation, feedback)
      assert_response :success
    end
    sign_out @course_admin

    sign_in staff_member
    evaluation.feedbacks.decided.each do |feedback|
      get evaluation_feedback_path(evaluation, feedback)
      assert_response :success
    end
    sign_out staff_member

    sign_in random_student
    evaluation.feedbacks.decided.each do |feedback|
      get evaluation_feedback_path(evaluation, feedback)
      assert_response :redirect
    end
    sign_out random_student

    sign_in student_from_evaluation
    evaluation.feedbacks.decided.each do |feedback|
      get evaluation_feedback_path(evaluation, feedback)
      assert_response :redirect
    end
    sign_out student_from_evaluation

    evaluation.feedbacks.decided.each do |feedback|
      get evaluation_feedback_path(evaluation, feedback)
      assert_response :redirect
    end
  end

  test 'Show page should only be available to zeus and course admins' do
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }

    evaluation = @series.evaluation
    evaluation.update(users: @users)
    random_student = create :student
    student_from_evaluation = @users.sample
    assert_not student_from_evaluation.admin_of?(@series.course)
    staff_member = create :staff
    @series.course.administrating_members << staff_member

    [@course_admin, staff_member].each do |person|
      sign_in person
      get evaluation_path(evaluation)
      assert_response :success, 'Should get access since the user is not a student'
      sign_out person
    end

    [student_from_evaluation, random_student].each do |person|
      sign_in person
      get evaluation_path(evaluation)
      assert_response :redirect, 'Should not get access since the user is a student'
      sign_out person
    end
  end

  test 'grade export is only available for course admins' do
    # Create an evaluation, a score item and add a score.
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    evaluation = @series.evaluation
    evaluation.update(users: @series.course.enrolled_members)
    # Add a score to a non-nil submission
    feedback = evaluation.feedbacks.where.not(submission_id: nil).sample
    exercise = feedback.evaluation_exercise
    score_item = create :score_item, evaluation_exercise: exercise
    score = create :score, score_item: score_item, feedback: feedback

    get export_grades_evaluation_path evaluation, format: :csv
    assert_response :success
    assert_equal 'text/csv', response.content_type

    # Check the contents of the csv file.
    csv = CSV.parse response.body
    assert_equal 1 + evaluation.evaluation_users.length, csv.size

    header = csv.shift
    assert_equal 4 + evaluation.evaluation_exercises.length * 2, header.length

    # Get which users will have a score
    # First, the users we added a score for.
    users = {
      feedback.evaluation_user.user.email => score.score
    }
    evaluation.feedbacks.where(submission_id: nil).map(&:evaluation_user).map(&:user).map(&:email).uniq.each do |u|
      users[u] = BigDecimal('0')
    end

    # The exercise with a score item has a different max.
    score_item_exercise_position = header.index { |h| h == "#{exercise.exercise.name} Score" }
    csv.each do |line|
      # Only one exercise has a score.
      if users.key?(line[1])
        exported_score = BigDecimal(line.delete_at(score_item_exercise_position))
        assert_equal users[line[1]], exported_score
      else
        exported_score = line.delete_at(score_item_exercise_position)
        assert_equal '', exported_score
      end
      exported_max = BigDecimal(line.delete_at(score_item_exercise_position))
      assert_equal score_item.maximum, exported_max

      # All other scores should be nil.
      assert line[4..].all?(&:empty?)
    end

    sign_out @course_admin

    # No log in
    get export_grades_evaluation_path evaluation, format: :csv
    assert_response :redirect # Redirect to sign in page

    random_user = @users.sample
    assert_not random_user.admin_of?(@series.course)

    sign_in random_user
    get export_grades_evaluation_path evaluation, format: :csv
    assert_response :redirect # Redirect to sign in page
  end

  test 'grade export contains correct data' do
    # Create an evaluation, a score item and add a score.
    post evaluations_path, params: {
      evaluation: {
        series_id: @series.id,
        deadline: DateTime.now
      }
    }
    evaluation = @series.evaluation
    evaluation.update(users: @series.course.enrolled_members)
    # Add a score to a non-nil submission
    feedback1 = evaluation.feedbacks.where.not(submission_id: nil).sample
    exercise1 = feedback1.evaluation_exercise
    score_item1 = create :score_item, evaluation_exercise: exercise1, maximum: 20
    create :score, score_item: score_item1, feedback: feedback1, score: 15

    # Add a score to another submission
    feedback2 = evaluation.feedbacks.where(evaluation_id: feedback1.evaluation_id).where.not(submission_id: feedback1.submission_id).sample
    exercise2 = feedback2.evaluation_exercise
    score_item2 = create :score_item, evaluation_exercise: exercise2, maximum: 10
    create :score, score_item: score_item2, feedback: feedback2, score: 7.5

    get export_grades_evaluation_path evaluation, format: :csv
    assert_response :success
    assert_equal 'text/csv', response.content_type

    # Check the contents of the csv file.
    csv = CSV.parse response.body
    csv.shift

    # Total score should equal sum of scores, Total max should equal the sum of maximum scores
    csv.each do |line|
      puts line
      # Possible that total maximum is present, but all scores are empty en thus total score is empty
      total_maximum = 0
      if line[2] == ''
        (4...line.length - 1).step(2).each do |index|
          assert_equal line[index], ''
          total_maximum += BigDecimal(line[index + 1]) unless line[index + 1] == ''
        end
      else
        total_score = 0
        (4..line.length - 1).step(2).each do |index|
          total_score += BigDecimal(line[index]) unless line[index] == ''
          total_maximum += BigDecimal(line[index + 1]) unless line[index + 1] == ''
        end

        assert_equal BigDecimal(line[2]), total_score

      end
      assert_equal BigDecimal(line[3]), total_maximum
    end
  end

  test 'course admins can change grade visibility' do
    evaluation = create :evaluation, :with_submissions
    evaluation.series.course.administrating_members << @course_admin
    from = evaluation.evaluation_exercises.first
    s1 = create :score_item, evaluation_exercise: from
    s2 = create :score_item, evaluation_exercise: from

    [
      [@course_admin, :redirect],
      [create(:student), :forbidden],
      [create(:staff), :forbidden],
      [create(:zeus), :redirect],
      [nil, :unauthorized]
    ].each do |user, expected|
      sign_in user if user.present?

      from.update!(visible_score: false)
      s1.update!(visible: false)
      s2.update!(visible: false)

      post modify_grading_visibility_evaluation_path(evaluation, format: :js), params: {
        visible: true
      }

      assert_response expected

      from.reload
      s1.reload
      s2.reload

      if expected == :redirect
        assert from.visible_score?
        assert s1.visible?
        assert s2.visible?
      else
        assert_not from.visible_score?
        assert_not s1.visible?
        assert_not s2.visible?
      end

      sign_out user if user.present?
    end
  end

  test 'evaluations overview is only visible if released' do
    evaluation = create :evaluation, :with_submissions
    feedback = evaluation.feedbacks.first
    submission = feedback.submission

    assert_not evaluation.released
    sign_in submission.user
    get overview_evaluation_path(evaluation)
    assert_response :redirect # Redirect to sign in page

    evaluation.update!(released: true)
    get overview_evaluation_path(evaluation)
    assert_response :ok
  end

  def expected_score_string(*args)
    if args.length == 1
      "#{format_score(args[0].score)} / #{format_score(args[0].score_item.maximum)}"
    else
      "#{format_score(args[0])} / #{format_score(args[1])}"
    end
  end

  test 'should only show allowed grades for students' do
    evaluation = create :evaluation, :released, :with_submissions
    evaluation_exercise = evaluation.evaluation_exercises.first
    visible_score_item = create :score_item, evaluation_exercise: evaluation_exercise
    hidden_score_item = create :score_item, evaluation_exercise: evaluation_exercise, visible: false
    feedback = evaluation.feedbacks.first
    submission = feedback.submission
    s1 = create :score, feedback: feedback, score_item: visible_score_item, score: BigDecimal('5.00')
    s2 = create :score, feedback: feedback, score_item: hidden_score_item, score: BigDecimal('7.00')

    sign_in submission.user

    # Visible scores are visible
    get overview_evaluation_path(evaluation)
    assert_match visible_score_item.description, response.body
    assert_no_match hidden_score_item.description, response.body
    assert_match expected_score_string(s1), response.body
    assert_no_match expected_score_string(s2), response.body
    assert_match expected_score_string(feedback.score, feedback.maximum_score), response.body

    # Hidden total is not shown
    evaluation_exercise.update!(visible_score: false)
    get overview_evaluation_path(evaluation)
    assert_match visible_score_item.description, response.body
    assert_no_match hidden_score_item.description, response.body
    assert_match expected_score_string(s1), response.body
    assert_no_match expected_score_string(s2), response.body
    assert_no_match expected_score_string(feedback.score, feedback.maximum_score), response.body
  end
end
