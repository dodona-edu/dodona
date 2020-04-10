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

  test 'can not create annotation for invalid line' do
    post submission_annotations_url(@submission), params: {
      annotation: {
        annotation_text: 'Should not be possible',
        line_nr: 2000
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
