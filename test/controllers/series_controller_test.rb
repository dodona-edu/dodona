require 'test_helper'

class SeriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    @instance = create(:series)
    sign_in create(:zeus)
  end

  test 'create series should redirect to edit' do
    instance = create_request_expect
    assert_redirected_to edit_series_url(instance)
  end

  test 'update series should redirect to course' do
    instance = update_request_expect
    assert_redirected_to course_url(instance.course, all: true, anchor: "series-#{instance.name.parameterize}")
  end

  test 'destroy series should redirect to course' do
    course = @instance.course
    destroy_request
    assert_redirected_to course_url(course)
  end

  crud_helpers Series, attrs: %i[name description course_id visibility order deadline]
  test_crud_actions except: %i[create_redirect update_redirect destroy_redirect]
end
