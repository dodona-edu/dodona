require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  test 'should get sign in page' do
    get sign_in_url
    assert_response :success
    assert_template 'auth/sign_in'
  end
end
