require 'test_helper'

class SamlControllerTest < ActionDispatch::IntegrationTest
  test 'SAML metadata' do
    # Validate whether the request works.
    get users_saml_metadata_path
    assert_response :success

    # Validate that actual metadata is returned.
    assert_includes response.content_type, 'application/xml'
  end
end
