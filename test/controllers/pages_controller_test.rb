require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test 'should get homepage' do
    get root_url
    assert_response :success
  end

  test 'should get sign in page' do
    get sign_in_url
    assert_response :success
    assert_template :sign_in_page
  end

  test 'should redirect to SAML sign in' do
    institution = create(:institution)
    get sign_in_url(idp: institution.short_name)
    assert_response :redirect
    assert_redirected_to new_user_session_url(idp: institution.short_name)
  end

  test 'should redirect to SSO' do
    institution = create(:institution)
    get new_user_session_url(idp: institution.short_name)
    assert_response :redirect
    assert_equal institution.sso_url, response.location.split('?').first
  end

  test 'should get contact page' do
    get contact_url
    assert_response :success
  end

  test 'should send email' do
    contact_form = {
      name: 'Jan',
      email: 'Jan@UGent.BE',
      subject: '(╯°□°）╯︵ ┻━┻)',
      message: '┬─┬ノ( º _ ºノ )'
    }
    assert_changes 'ActionMailer::Base.deliveries.size', +1 do
      post create_contact_path(contact_form: contact_form)
    end
    assert_redirected_to root_url
  end
end
