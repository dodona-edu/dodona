require 'test_helper'

class AnnotationControllerTest < ActionDispatch::IntegrationTest
  def setup
    @submission = create :correct_submission, code: "line1\nline2\nline3\n"
    @zeus = create(:zeus)
    sign_in @zeus
  end

  test 'can create global annotation' do
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: nil,
        annotation_text: 'Not available'
      },
      format: :json
    }

    assert_response :created
  end

  test 'can create line-bound annotation' do
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Not available'
      },
      format: :json
    }

    assert_response :created
  end

  test 'annotation index should contain all annotations user can see' do
    user = create :user
    other_user = create :user
    course = create :course
    course_admin = create :user
    course_admin.update(administrating_courses: [course])

    create :annotation, user: user, submission: (create :submission, user: user, course: course)
    create :annotation, user: user, submission: (create :submission, user: user, course: course)
    create :annotation, user: user, submission: (create :submission, user: user)
    create :annotation, user: other_user, submission: (create :submission, user: other_user, course: course)
    create :annotation, user: other_user, submission: (create :submission, user: other_user)

    get annotations_url(format: :json)
    assert_equal 5, JSON.parse(response.body).count

    sign_in course_admin
    get annotations_url(format: :json)
    assert_equal 3, JSON.parse(response.body).count

    sign_in user
    get annotations_url(format: :json)
    assert_equal 3, JSON.parse(response.body).count
  end

  test 'annotation index should be filterable by user' do
    user = create :user
    other_user = create :user

    create :annotation, user: user, submission: (create :submission, user: user)
    create :annotation, user: user, submission: (create :submission, user: user)
    create :annotation, user: user, submission: (create :submission, user: user)
    create :annotation, user: other_user, submission: (create :submission, user: other_user)
    create :annotation, user: other_user, submission: (create :submission, user: other_user)

    get annotations_url(format: :json, user_id: user.id)
    assert_equal 3, JSON.parse(response.body).count

    get annotations_url(format: :json, user_id: other_user.id)
    assert_equal 2, JSON.parse(response.body).count
  end

  test 'user who created submission should be able to see the annotation' do
    annotation = create :annotation, submission: @submission, user: @zeus
    sign_in @submission.user

    get annotation_url(annotation, format: :json)
    assert_response :success
  end

  test 'unrelated user should not be able to see the annotation' do
    annotation = create :annotation, submission: @submission, user: @zeus
    sign_in create(:user)

    get annotation_url(annotation, format: :json)
    assert_response :forbidden
  end

  test 'can update annotation, but only the content' do
    annotation = create :annotation, submission: @submission, user: @zeus

    put annotation_url(annotation), params: {
      annotation: {
        annotation_text: 'We changed this text'
      },
      format: :json
    }
    assert_response :success

    patch annotation_url(annotation), params: {
      annotation: {
        annotation_text: 'We changed this text again'
      },
      format: :json
    }
    assert_response :success
  end

  test 'can remove annotation' do
    annotation = create :annotation, submission: @submission, user: @zeus
    delete annotation_url(annotation)
    assert_response :no_content
  end

  test 'can not create invalid annotation' do
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'A' * 2049 # max length of annotation text is 2048 -> trigger failure
      },
      format: :json
    }
    assert_response :unprocessable_entity
  end

  test 'can not update valid annotation with invalid annotation' do
    annotation = create :annotation, submission: @submission, user: @zeus

    put annotation_url(annotation), params: {
      annotation: {
        annotation_text: 'A' * 2049 # max length of annotation text is 2048 -> trigger failure
      },
      format: :json
    }

    assert_response :unprocessable_entity
  end

  test 'can query the index of all annotations on a submission' do
    create :annotation, submission: @submission, user: @zeus
    create :annotation, submission: @submission, user: @zeus
    create :annotation, submission: @submission, user: @zeus

    get submission_annotations_url(@submission), params: { format: :json }

    assert_response :ok
  end
end

# Separate class, since this needs separate setup
class QuestionAnnotationControllerTest < ActionDispatch::IntegrationTest
  def setup
    questionable_course = create :course, enabled_questions: true
    @submission = create :correct_submission, code: "line1\nline2\nline3\n", course: questionable_course
    sign_in @submission.user
  end

  test 'student can create a question' do
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :created
    assert @submission.questions.any?
  end

  test 'student cannot create a question if disabled for course' do
    course = create :course, enabled_questions: false
    submission = create :submission, course: course
    sign_in submission.user

    post submission_annotations_url(submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :forbidden

    assert_equal submission.user.questions.count, 0, 'Student is not allowed to create questions'
  end

  test 'student cannot create question if no course' do
    submission = create :submission, course: nil
    sign_in submission.user

    post submission_annotations_url(submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :forbidden

    assert_equal submission.user.questions.count, 0, 'Student is not allowed to create questions without course'
  end

  test 'random user cannot create question' do
    sign_in create(:user)
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :forbidden
  end

  test 'zeus cannot create question' do
    sign_in create(:zeus)
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :created
    assert_not @submission.questions.any?
  end

  test 'staff cannot create question' do
    sign_in create(:staff)
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :forbidden
  end

  test 'course admin cannot create question' do
    admin = create(:staff)
    @submission.course.administrating_members = [admin]
    sign_in admin
    post submission_annotations_url(@submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :created
    assert_not @submission.questions.any?
  end

  test 'questions can transition from unanswered' do
    zeus = create :zeus
    staff = create :staff
    @submission.course.administrating_members = [create(:staff)]
    admin = @submission.course.administrating_members[0]
    random = create :user

    users = [[zeus, true], [staff, false], [admin, true], [random, false]]

    users.each do |user, valid|
      sign_in user

      # Unanswered -> in progress
      question = create :question, submission: @submission, question_state: :unanswered
      post in_progress_annotation_path(question), params: {
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # Unanswered -> answered
      question = create :question, submission: @submission, question_state: :unanswered
      post resolve_annotation_path(question), params: {
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # Unanswered -> unanswered
      question = create :question, submission: @submission, question_state: :unanswered
      post unresolve_annotation_path(question), params: {
        format: :json
      }
      assert_response :forbidden

      sign_out user
    end
  end

  test 'a student can mark their own questions answered' do
    # Unanswered -> answered
    question = create :question, submission: @submission, question_state: :unanswered
    post resolve_annotation_path(question), params: {
      format: :json
    }
    assert_response :ok

    # Answered -> answered
    question = create :question, submission: @submission, question_state: :answered
    post resolve_annotation_path(question), params: {
      format: :json
    }
    assert_response :forbidden

    # In progress -> answered
    question = create :question, submission: @submission, question_state: :in_progress
    post resolve_annotation_path(question), params: {
      format: :json
    }
    assert_response :ok
  end

  test 'questions can transition from in_progress' do
    zeus = create :zeus
    staff = create :staff
    @submission.course.administrating_members = [create(:staff)]
    admin = @submission.course.administrating_members[0]
    random = create :user

    users = [[zeus, true], [staff, false], [admin, true], [random, false]]
    users.each do |user, valid|
      sign_in user

      # In progress -> in progress
      question = create :question, submission: @submission, question_state: :in_progress
      post in_progress_annotation_path(question), params: {
        format: :json
      }
      assert_response :forbidden

      # In progress -> answered
      question = create :question, submission: @submission, question_state: :in_progress
      post resolve_annotation_path(question), params: {
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # In progress -> unanswered
      question = create :question, submission: @submission, question_state: :in_progress
      post unresolve_annotation_path(question), params: {
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      sign_out user
    end
  end

  test 'questions can transition from answered' do
    zeus = create :zeus
    staff = create :staff
    @submission.course.administrating_members = [create(:staff)]
    admin = @submission.course.administrating_members[0]
    random = create :user

    users = [[zeus, true], [staff, false], [admin, true], [random, false]]
    users.each do |user, valid|
      sign_in user

      # Answered -> in progress
      question = create :question, submission: @submission, question_state: :answered
      post in_progress_annotation_path(question), params: {
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # Answered -> answered
      question = create :question, submission: @submission, question_state: :answered
      post resolve_annotation_path(question), params: {
        format: :json
      }
      assert_response :forbidden

      # Answered -> unanswered
      question = create :question, submission: @submission, question_state: :answered
      post unresolve_annotation_path(question), params: {
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      sign_out user
    end
  end

  test 'cannot delete if question was answered' do
    question = create :question, submission: @submission, question_state: :answered

    delete annotation_url(question)
    assert_not response.successful?

    question = create :question, submission: @submission, question_state: :unanswered

    delete annotation_url(question)
    assert_response :no_content
  end

  test 'cannot modify if question was answered' do
    question = create :question, submission: @submission, question_state: :answered

    put annotation_path(question), params: {
      annotation: {
        annotation_text: 'Changed'
      },
      format: :json
    }
    assert_response :forbidden

    question = create :question, submission: @submission, question_state: :unanswered

    put annotation_path(question), params: {
      annotation: {
        annotation_text: 'Changed'
      },
      format: :json
    }
    assert_response :success
  end
end
