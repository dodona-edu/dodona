require 'test_helper'

class SamlControllerTest < ActionDispatch::IntegrationTest
  test 'logout with saml' do
    institution = create :saml_institution
    user = create :user, institution: institution

    sign_in user

    delete destroy_user_session_path(idp: institution.short_name)

    assert_equal institution.slo_url, @response.location.split('?').first
    assert_nil @controller.current_user
  end

  test 'logout without saml (using oauth)' do
    institution = create :smartschool_institution
    user = create :user, institution: institution

    sign_in user

    delete destroy_user_session_path

    assert_redirected_to root_url
    assert_nil @controller.current_user
  end

  test 'SAML metadata' do
    get metadata_user_session_path
    assert_response :success
  end
end
