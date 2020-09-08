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

  test 'student can create a question' do
    student = create :student
    sign_in student
    student_submission = create :submission, user: student

    post submission_annotations_url(student_submission), params: {
      annotation: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :created

    post submission_annotations_url(student_submission), params: {
      annotation: {
        line_nr: nil,
        annotation_text: 'Ik heb een vraag over mijn code - Globaal'
      },
      format: :json
    }

    assert_response :created

    assert_equal student.questions.count, 2, 'Student must have been able to create 2 questions'
  end

  test 'students can only have 5 unanswered questions' do
    student = create :student
    sign_in student
    student_submission = create :submission, user: student

    create_list :question, 5, submission: student_submission, user: student

    assert_equal student.questions.count, 5, 'Created questions are available'
    assert_equal student.questions.where(question_state: :unanswered).count, 5, 'Created questions are unanswered'

    post submission_annotations_url(student_submission), params: {
      annotation: {
        line_nr: nil,
        annotation_text: 'Ik heb een vraag over mijn code - Globaal'
      },
      format: :json
    }

    assert_response :forbidden
  end

  test 'questions can evolve from unanswered to in progress or to answered' do
    student = create :student
    student_submission = create :submission, user: student

    questions = create_list :question, 5, submission: student_submission, user: student

    assert_equal student_submission.questions.where(question_state: :unanswered).count, 5, 'All questions should start unanswered'
    assert_equal student_submission.questions.where(question_state: :in_progress).count, 0, 'All questions should start unanswered'
    assert_equal student_submission.questions.where(question_state: :answered).count, 0, 'All questions should start unanswered'

    questions.each do |question|
      post in_progress_annotation_path(question), params: {
        format: :json
      }
      assert_response :ok
    end
    assert_equal student_submission.questions.where(question_state: :unanswered).count, 0, 'All questions should be transformed to in progress'
    assert_equal student_submission.questions.where(question_state: :in_progress).count, 5, 'All questions should be transformed to in progress'
    assert_equal student_submission.questions.where(question_state: :answered).count, 0, 'All questions should be transformed to in progress'

    questions.each do |question|
      post resolve_annotation_path(question), params: {
        format: :json
      }
      assert_response :ok
    end
    assert_equal student_submission.questions.where(question_state: :unanswered).count, 0, 'All questions should be transformed to answered'
    assert_equal student_submission.questions.where(question_state: :in_progress).count, 0, 'All questions should be transformed to answered'
    assert_equal student_submission.questions.where(question_state: :answered).count, 5, 'All questions should be transformed to answered'
  end

  test 'questions can evolve from unanswered to answered without going trough in progress -- In person explanation' do
    student = create :student
    student_submission = create :submission, user: student

    questions = create_list :question, 5, submission: student_submission, user: student

    assert_equal student_submission.questions.where(question_state: :unanswered).count, 5, 'All questions should start unanswered'
    assert_equal student_submission.questions.where(question_state: :in_progress).count, 0, 'All questions should start unanswered'
    assert_equal student_submission.questions.where(question_state: :answered).count, 0, 'All questions should start unanswered'

    questions.each do |question|
      post resolve_annotation_path(question), params: {
        format: :json
      }
      assert_response :ok
    end
    assert_equal student_submission.questions.where(question_state: :unanswered).count, 0, 'All questions should be transformed to answered'
    assert_equal student_submission.questions.where(question_state: :in_progress).count, 0, 'All questions should be transformed to answered'
    assert_equal student_submission.questions.where(question_state: :answered).count, 5, 'All questions should be transformed to answered'
  end

  test 'a student can mark their own questions answered' do
    student = create :student
    student_submission = create :submission, user: student

    questions = create_list :question, 5, submission: student_submission, user: student

    assert_equal student_submission.questions.where(question_state: :unanswered).count, 5, 'All questions should start unanswered'
    assert_equal student_submission.questions.where(question_state: :in_progress).count, 0, 'All questions should start unanswered'
    assert_equal student_submission.questions.where(question_state: :answered).count, 0, 'All questions should start unanswered'

    sign_in student
    questions.each do |question|
      post resolve_annotation_path(question), params: {
        format: :json
      }
      assert_response :ok
    end
    assert_equal student_submission.questions.where(question_state: :unanswered).count, 0, 'All questions should be transformed to answered'
    assert_equal student_submission.questions.where(question_state: :in_progress).count, 0, 'All questions should be transformed to answered'
    assert_equal student_submission.questions.where(question_state: :answered).count, 5, 'All questions should be transformed to answered'
  end
end
