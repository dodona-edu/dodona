require 'test_helper'

class SavedAnnotationControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers SavedAnnotation, attrs: %i[title annotation_text]

  def setup
    @course = create :course
    @user = users(:staff)
    CourseMembership.create(course: @course, user: @user, status: :course_admin)
    @instance = create :saved_annotation, user: @user, course: @course
    sign_in @user
  end

  test_crud_actions only: %i[show destroy index update edit]

  test 'should be able to create from existing annotation' do
    annotation = create :annotation, submission:  create(:submission, course: @course), user: @user
    post saved_annotations_url, params: { format: :json, saved_annotation: { title: 'test', annotation_text: annotation.annotation_text }, from: annotation.id }

    assert_response :success
  end

  test 'creating a saved annotation should work when one with the same name already exists' do
    annotation = create :annotation, submission:  create(:submission, course: @course), user: @user
    post saved_annotations_url, params: { format: :json, saved_annotation: { title: 'test', annotation_text: annotation.annotation_text }, from: annotation.id }

    assert_response :success
    post saved_annotations_url, params: { format: :json, saved_annotation: { title: 'test', annotation_text: annotation.annotation_text }, from: annotation.id }

    assert_response :success
  end

  test 'zeus should not have access to saved annotations of other users' do
    sign_in users(:staff)
    get saved_annotations_url, params: { format: :json }

    assert_response :success
    assert_equal 1, response.parsed_body.length

    sign_in users(:zeus)
    get saved_annotations_url, params: { format: :json }

    assert_response :success
    assert_equal 0, response.parsed_body.length

    get saved_annotation_url(@instance), params: { format: :json }

    assert_response :forbidden
  end
end
