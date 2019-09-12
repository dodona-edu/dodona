require 'test_helper'

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def omniauth_mock_user(user, params = {})
    auth_hash = {
      provider: user.institution&.provider,
      uid: user.username,
      info: {
        email: user.email,
        first_name: user.first_name,
        last_name: user.last_name,
        institution: user.institution&.identifier
      }
    }.deep_merge(params)
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

  test 'login with smartschool without email should work' do
    institution = create :smartschool_institution
    user = build :user, email: nil, institution: institution
    omniauth_mock_user user

    assert_difference 'User.count', +1 do
      get user_smartschool_omniauth_authorize_url
      follow_redirect!
    end

    assert_equal @controller.current_user.username, user.username
    assert_nil @controller.current_user.email
  end

  test 'login with office365 without email should not work' do
    institution = create :office365_institution
    user = build :user, email: nil, institution: institution
    omniauth_mock_user user

    assert_difference 'User.count', 0 do
      get user_office365_omniauth_authorize_url
      follow_redirect!
    end

    assert_nil @controller.current_user
  end

  test 'should not sign in when user tries to sign in with same email from different provider/institution' do
    first_user_insitution = create :smartschool_institution
    first_user = create :user, institution: first_user_insitution

    second_institution = create :smartschool_institution
    second_user = build :user, email: first_user.email, institution: second_institution
    omniauth_mock_user second_user

    assert_difference 'User.count', 0 do
      get user_smartschool_omniauth_authorize_url
      follow_redirect!
    end

    assert_redirected_to root_path
    assert_nil @controller.current_user
    assert_not_equal first_user.reload.username, second_user.username
  end

  test 'login with unknown institution should not work' do
    institution = build :smartschool_institution
    user = build :user, institution: institution
    omniauth_mock_user user

    assert_difference 'User.count', 1 do
      assert_difference 'Institution.count', 1 do
        get user_smartschool_omniauth_authorize_url
        follow_redirect!
      end
    end
    assert_enqueued_jobs 1 # an email should be sent

    assert_redirected_to root_path
    assert_not_nil @controller.current_user
  end

  test 'failure' do
    OmniAuth.config.mock_auth[:default] = :invalid_credentials

    get user_smartschool_omniauth_authorize_url
    follow_redirect!

    assert_redirected_to root_path
    assert_nil @controller.current_user
  end

  test 'login with temporary user should convert them to normal' do
    user = create :temporary_user
    username = 'real_username'
    institution = create :smartschool_institution
    omniauth_mock_user user,
                       provider: 'smartschool',
                       uid: username,
                       info: {
                         institution: institution.identifier
                       }

    get user_smartschool_omniauth_authorize_url
    follow_redirect!

    user.reload
    assert_equal user, @controller.current_user
    assert_equal 'real_username', user.username
    assert_equal institution, user.institution

    sign_out :user
    omniauth_mock_user user
    get user_smartschool_omniauth_authorize_url
    follow_redirect!

    assert_equal user, @controller.current_user, 'temp user should be still able to sign in after conversion'
  end

  test 'ugent user trying to login with office365 should be redirected to SAML' do
    ugent_identifier = 'd7811cde-ecef-496c-8f91-a1786241b99c'
    user = create :user
    omniauth_mock_user user,
                       provider: 'office365',
                       info: {
                         institution: ugent_identifier
                       }

    get user_office365_omniauth_authorize_url
    follow_redirect!

    assert_redirected_to sign_in_path(idp: 'UGent')
    assert_nil @controller.current_user
  end

  test 'user attributes should be updated with oauth login' do
    institution = create :office365_institution
    user = create :user, institution: institution

    omniauth_mock_user user,
                       uid: 'flipflap',
                       info: {
                         first_name: 'Flip',
                         last_name: 'Flapstaart'
                       }

    get user_office365_omniauth_authorize_url
    follow_redirect!

    user.reload
    assert_equal user, @controller.current_user
    assert_equal user.username, 'flipflap'
    assert_equal user.first_name, 'Flip'
    assert_equal user.last_name, 'Flapstaart'
  end

  test 'update attributes should be checked for validity' do
    institution = create :office365_institution
    first_user = create :user, institution: institution
    user = create :user, institution: institution

    # username colission
    omniauth_mock_user user, uid: first_user.username

    get user_office365_omniauth_authorize_url
    follow_redirect!

    user.reload
    assert_redirected_to root_path
    assert_nil @controller.current_user
    user.reload
    assert_not_equal first_user.username, user.username
  end
end
