require 'test_helper'

class RightsRequestsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers RightsRequest, attrs: %i[context institution_name]

  setup do
    sign_in create(:student)
  end

  test_crud_actions only: %i[new create], except: %i[create_redirect]

  test 'creation should send email' do
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      attrs = generate_attr_hash
      create_request(attr_hash: attrs)
      assert_redirected_to root_path
    end
  end

  test 'zeus should be able to get index' do
    create(:rights_request)
    sign_in create(:zeus)
    get rights_requests_url
    assert_response :success
  end

  test 'others should not be able to get index' do
    create(:rights_request)
    get rights_requests_url
    assert_redirected_to root_path
  end

  test 'zeus should be able to approve' do
    sign_in create(:zeus)
    req = create(:rights_request)
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      post approve_rights_request_url(req, format: :js)
    end
    assert_response :success

    req = create(:rights_request)
    post approve_rights_request_url(req)
    assert_redirected_to rights_requests_path
  end

  test 'approval should update institution name' do
    sign_in create(:zeus)
    req = create(:rights_request)
    req.update(institution_name: req.user.institution.name + 'different')
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      post approve_rights_request_url(req, format: :js)
    end
    assert_response :success
    assert_equal req.institution_name, req.user.institution.reload.name
  end

  test 'others should not be able to approve' do
    req = create(:rights_request)
    assert_difference 'ActionMailer::Base.deliveries.size', 0 do
      post approve_rights_request_url(req)
    end
    assert_redirected_to root_path
  end

  test 'zeus should be able to reject' do
    sign_in create(:zeus)
    req = create(:rights_request)
    assert_difference 'ActionMailer::Base.deliveries.size', 1 do
      post reject_rights_request_url(req, format: :js)
    end
    assert_response :success

    req = create(:rights_request)
    post reject_rights_request_url(req)
    assert_redirected_to rights_requests_path
  end

  test 'others should not be able to reject' do
    req = create(:rights_request)
    post reject_rights_request_url(req)
    assert_redirected_to root_path
  end
end
