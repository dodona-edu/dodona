require 'test_helper'

class SavedAnnotationControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers SavedAnnotation, attrs: %i[title annotation_text], format: :json

  def setup
    @course = create :course, id: 10 # COURSE ID CAN BE REMOVED AFTER CLOSED BETA
    @user = users(:staff)
    CourseMembership.create(course: @course, user: @user, status: :course_admin)
    @instance = create :saved_annotation, user: @user, course: @course
    sign_in @user
  end

  test_crud_actions only: %i[show destroy index update], except: %i[update_redirect destroy_redirect]

  test 'should be able to create from existing annotation' do
    annotation = create :annotation, submission:  create(:submission, course: @course), user: @user
    post saved_annotations_url, params: { format: :json, saved_annotation: { title: 'test', annotation_text: annotation.annotation_text }, from: annotation.id }
    assert_response :success
  end

  test 'creating a saved annotation should fail when one with the same name already exists' do
    annotation = create :annotation, submission:  create(:submission, course: @course), user: @user
    post saved_annotations_url, params: { format: :json, saved_annotation: { title: 'test', annotation_text: annotation.annotation_text }, from: annotation.id }
    assert_response :success
    post saved_annotations_url, params: { format: :json, saved_annotation: { title: 'test', annotation_text: annotation.annotation_text }, from: annotation.id }
    assert_response :unprocessable_entity
  end
end
