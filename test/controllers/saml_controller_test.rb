require 'test_helper'

class SamlControllerTest < ActionDispatch::IntegrationTest
  test 'logout with saml' do
    institution = create :saml_institution
    user = create :user, institution: institution

    sign_in user

    delete users_sign_out_path

    assert_nil @controller.current_user
  end

  test 'SAML metadata' do
    get users_saml_metadata_path
    assert_response :success
  end
end
