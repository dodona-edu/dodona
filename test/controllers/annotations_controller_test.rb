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

  test 'should be able to search by exercise name' do
    u = create :user
    sign_in u
    e1 = create :exercise, name_en: 'abcd'
    e2 = create :exercise, name_en: 'efgh'
    s1 = create :submission, exercise: e1, user: u
    s2 = create :submission, exercise: e2, user: u
    create :question, submission: s1
    create :question, submission: s2

    get questions_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to search by user name' do
    u1 = create :user, last_name: 'abcd'
    u2 = create :user, last_name: 'efgh'
    s1 = create :submission, user: u1
    s2 = create :submission, user: u2
    create :question, submission: s1
    create :question, submission: s2

    get questions_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to filter by status' do
    u = create :user
    sign_in u
    s = create :submission, user: u
    create :question, question_state: :in_progress, submission: s
    create :question, question_state: :unanswered, submission: s
    create :question, question_state: :answered, submission: s

    get questions_url, params: { question_state: 'answered', format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to filter by course' do
    u = create :user
    sign_in u
    s1 = create :course_submission, user: u
    s2 = create :course_submission, user: u
    create :question, submission: s1
    create :question, submission: s2

    # Filter mode
    get questions_url, params: { course_id: s1.course.id, format: :json }

    assert_equal 1, JSON.parse(response.body).count

    # "Course" mode
    get questions_url, params: { course: s2.course.id, format: :json }

    assert_equal 1, JSON.parse(response.body).count
  end

  test 'should be able to filter by user' do
    u = create :zeus
    sign_in u
    s1 = create :course_submission
    s2 = create :course_submission
    create :question, submission: s1
    create :question, submission: s2

    # Filter mode
    get questions_url, params: { user_id: s1.user_id, format: :json }

    assert_equal 1, JSON.parse(response.body).count
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

  test 'not logged in is rejected' do
    sign_out @submission.user
    post submission_annotations_url(@submission), params: {
      question: {
        line_nr: 1,
        annotation_text: 'Ik heb een vraag over mijn code - Lijn'
      },
      format: :json
    }
    assert_response :unauthorized
  end

  test 'student can create a question' do
    post submission_annotations_url(@submission), params: {
      question: {
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
      question: {
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
      question: {
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
      question: {
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
      question: {
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
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :in_progress
        },
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # Unanswered -> answered
      question = create :question, submission: @submission, question_state: :unanswered
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :answered
        },
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # Unanswered -> unanswered
      question = create :question, submission: @submission, question_state: :unanswered
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :unanswered
        },
        format: :json
      }
      assert_response :forbidden

      sign_out user
    end
  end

  test 'a student can mark their own questions answered' do
    # Unanswered -> answered
    question = create :question, submission: @submission, question_state: :unanswered
    patch annotation_path(question), params: {
      from: question.question_state,
      question: {
        question_state: :answered
      },
      format: :json
    }
    assert_response :ok

    # Answered -> answered
    question = create :question, submission: @submission, question_state: :answered
    patch annotation_path(question), params: {
      from: question.question_state,
      question: {
        question_state: :answered
      },
      format: :json
    }
    assert_response :forbidden

    # In progress -> answered
    question = create :question, submission: @submission, question_state: :in_progress
    patch annotation_path(question), params: {
      from: question.question_state,
      question: {
        question_state: :answered
      },
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
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :in_progress
        },
        format: :json
      }
      assert_response :forbidden

      # In progress -> answered
      question = create :question, submission: @submission, question_state: :in_progress
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :answered
        },
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # In progress -> unanswered
      question = create :question, submission: @submission, question_state: :in_progress
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :unanswered
        },
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      sign_out user
    end
  end

  test 'question cannot transition if already changed' do
    sign_in create :zeus

    question = create :question, submission: @submission, question_state: :unanswered
    patch annotation_path(question), params: {
      from: :answered,
      question: {
        question_state: :in_progress
      },
      format: :json
    }
    assert_response :forbidden

    patch annotation_path(question), params: {
      question: {
        question_state: :in_progress
      },
      format: :json
    }
    assert_response :ok

    question = create :question, submission: @submission, question_state: :answered
    patch annotation_path(question), params: {
      from: :unanswered,
      question: {
        question_state: :in_progress
      },
      format: :json
    }
    assert_response :forbidden

    patch annotation_path(question), params: {
      question: {
        question_state: :in_progress
      },
      format: :json
    }
    assert_response :ok
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
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :in_progress
        },
        format: :json
      }
      assert_response valid ? :ok : :forbidden

      # Answered -> answered
      question = create :question, submission: @submission, question_state: :answered
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :answered
        },
        format: :json
      }
      assert_response :forbidden

      # Answered -> unanswered
      question = create :question, submission: @submission, question_state: :answered
      patch annotation_path(question), params: {
        from: question.question_state,
        question: {
          question_state: :unanswered
        },
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
      question: {
        annotation_text: 'Changed'
      },
      format: :json
    }
    assert_response :forbidden

    question = create :question, submission: @submission, question_state: :unanswered

    put annotation_path(question), params: {
      question: {
        annotation_text: 'Changed'
      },
      format: :json
    }
    assert_response :success
  end
end
