require 'test_helper'

class RightsRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @rights_request = rights_requests(:one)
  end

  test 'should get index' do
    get rights_requests_url
    assert_response :success
  end

  test 'should get new' do
    get new_rights_request_url
    assert_response :success
  end

  test 'should create rights_request' do
    assert_difference('RightsRequest.count') do
      post rights_requests_url, params: { rights_request: { context: @rights_request.context, institution_name: @rights_request.institution_name, user_id_id: @rights_request.user_id_id } }
    end

    assert_redirected_to rights_request_url(RightsRequest.last)
  end

  test 'should show rights_request' do
    get rights_request_url(@rights_request)
    assert_response :success
  end

  test 'should get edit' do
    get edit_rights_request_url(@rights_request)
    assert_response :success
  end

  test 'should update rights_request' do
    patch rights_request_url(@rights_request), params: { rights_request: { context: @rights_request.context, institution_name: @rights_request.institution_name, user_id_id: @rights_request.user_id_id } }
    assert_redirected_to rights_request_url(@rights_request)
  end

  test 'should destroy rights_request' do
    assert_difference('RightsRequest.count', -1) do
      delete rights_request_url(@rights_request)
    end

    assert_redirected_to rights_requests_url
  end
end
