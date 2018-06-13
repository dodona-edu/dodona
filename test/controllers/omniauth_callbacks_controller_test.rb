require 'test_helper'

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def omniauth_mock_user(user, params = {})
    auth_hash = {
      provider: user.institution.provider,
      uid: user.username,
      info: {
        username: user.username,
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        institution: user.institution.identifier
      }
    }.merge(params)
    OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(auth_hash)
  end

  test 'login using smartschool with existing user' do
    institution = create :smartschool_institution
    user = create :user, institution: institution
    omniauth_mock_user user

    get user_smartschool_omniauth_authorize_url
    follow_redirect!

    assert_redirected_to root_path
    assert_equal @controller.current_user, user
  end

  test 'login using office365 with existing user' do
    institution = create :office365_institution
    user = create :user, institution: institution
    omniauth_mock_user user

    get user_office365_omniauth_authorize_url
    follow_redirect!

    assert_redirected_to root_path
    assert_equal @controller.current_user, user
  end

  test 'first login should create user' do
    institution = create :smartschool_institution
    user = build :user, institution: institution
    omniauth_mock_user user

    assert_difference 'User.count', +1 do
      get user_smartschool_omniauth_authorize_url
      follow_redirect!
    end

    assert_redirected_to root_path
    assert_equal @controller.current_user.email, user.email
  end

  test 'should not create user when email is already in the system' do
    first_user = create :user
    institution = create :smartschool_institution
    user = build :user, email: first_user.email, institution: institution
    omniauth_mock_user user

    assert_difference 'User.count', 0 do
      get user_smartschool_omniauth_authorize_url
      follow_redirect!
    end

    assert_redirected_to root_path
    assert_nil @controller.current_user
  end

  test 'login with unknown institution should not work' do
    institution = build :smartschool_institution
    user = build :user, institution: institution
    omniauth_mock_user user

    assert_difference 'User.count', 0 do
      get user_smartschool_omniauth_authorize_url
      follow_redirect!
    end
    assert_enqueued_jobs 1 # an email should be sent

    assert_redirected_to root_path
    assert_nil @controller.current_user
  end

  test 'failure' do
    OmniAuth.config.mock_auth[:default] = :invalid_credentials

    get user_smartschool_omniauth_authorize_url
    follow_redirect!

    assert_redirected_to root_path
    assert_nil @controller.current_user
  end
end
