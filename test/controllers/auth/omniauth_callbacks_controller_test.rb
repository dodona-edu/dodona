require 'test_helper'

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def omniauth_mock_identity(identity, params = {})
    # Generic hash.
    auth_hash = {
      provider: identity.provider.class.sym.to_s,
      uid: identity.identifier,
      info: {
        email: identity.user.email,
        first_name: identity.user.first_name,
        last_name: identity.user.last_name,
        institution: identity.provider.identifier
      },
      extra: {
        raw_info: {
          hd: identity.provider.identifier
        }
      }
    }.deep_merge(params)

    # SAML includes the provider.
    auth_hash = auth_hash.deep_merge({ extra: { provider: identity.provider } }) if identity.provider.class == Provider::Saml

    OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(auth_hash)
  end

  def omniauth_url(provider)
    send(format('user_%<sym>s_omniauth_authorize_url', sym: provider.class.sym))
  end

  test 'login with existing identity' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name
      user = create :user, institution: provider.institution
      identity = create :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      get omniauth_url(provider)
      follow_redirect!

      # Assert successful authentication.
      assert_redirected_to root_path
      assert_equal @controller.current_user, user

      # Cleanup.
      sign_out user
    end
  end

  test 'login as a new user' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name
      user = build :user, institution: provider.institution
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      assert_difference 'User.count', 1 do
        assert_difference 'Identity.count', 1 do
          get omniauth_url(provider)
          follow_redirect!
        end
      end

      # Assert successful authentication.
      assert_redirected_to root_path
      assert_equal @controller.current_user.email, user.email

      # Cleanup.
      sign_out user
    end
  end

  test 'login using oauth with new institution' do
    OAUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = build provider_name
      user = build :user, institution: provider.institution
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      assert_difference 'User.count', 1 do
        assert_difference 'Identity.count', 1 do
          assert_difference 'Institution.count', 1 do
            get omniauth_url(provider)
            follow_redirect!
          end
        end
      end

      # Assert creation email has been sent.
      assert_enqueued_jobs 1

      # Assert successful authentication.
      assert_redirected_to root_path
      assert_not_nil @controller.current_user

      # Cleanup.
      clear_enqueued_jobs
      sign_out user
    end
  end

  test 'user trying to login with redirect provider should be redirected to preferred' do
    # Setup.
    institution = create :institution
    preferred_provider = create :provider, institution: institution
    redirect_provider = create :office365_provider, institution: institution, mode: :redirect
    user = build :user
    identity = build :identity, provider: redirect_provider, user: user
    omniauth_mock_identity identity,
                           provider: redirect_provider.class.sym,
                           info: {
                             institution: redirect_provider.identifier
                           }

    get omniauth_url(redirect_provider)
    follow_redirect!

    assert_redirected_to %r{/users/auth/#{preferred_provider.class.sym}/}
    assert_nil @controller.current_user
  end

  test 'user attributes should be updated upon login' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name
      user = create :user, institution: provider.institution
      identity = create :identity, provider: provider, user: user
      omniauth_mock_identity identity,
                             info: {
                               first_name: 'Flip',
                               last_name: 'Flapstaart'
                             }

      get omniauth_url(provider)
      follow_redirect!

      user.reload
      assert_equal user, @controller.current_user
      assert_equal 'Flip', user.first_name
      assert_equal 'Flapstaart', user.last_name

      # Cleanup.
      sign_out user
    end
  end

  test 'update attributes should be checked for validity' do
    OAUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name
      user = create :user, institution: provider.institution
      other_user = create :user
      identity = create :identity, provider: provider, user: user

      omniauth_mock_identity identity,
                             info: {
                               email: other_user.email
                             }

      assert_emails 1 do
        get omniauth_url(provider)
        follow_redirect!
      end

      user.reload
      assert_redirected_to root_path
      assert_nil @controller.current_user
      user.reload
      assert_not_equal other_user.email, user.email

      # Cleanup.
      sign_out user
    end
  end

  test 'login with smartschool without email address' do
    provider = create :smartschool_provider
    user = build :user, email: nil, institution: provider.institution
    identity = build :identity, provider: provider, user: user
    omniauth_mock_identity identity

    assert_difference 'User.count', +1 do
      get omniauth_url(provider)
      follow_redirect!
    end

    assert_equal @controller.current_user.username, user.username
    assert_nil @controller.current_user.email
  end

  test 'login with a non-smartschool without email should not work' do
    (AUTH_PROVIDERS - [:smartschool_provider]).each do |provider_name|
      provider = create provider_name
      user = build :user, email: nil, institution: provider.institution
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      assert_difference 'User.count', 0 do
        get omniauth_url(provider)
        follow_redirect!
      end

      assert_nil @controller.current_user

      # Cleanup.
      sign_out user
    end
  end

  test 'login with other institution should not work' do
    AUTH_PROVIDERS.each do |provider_name|
      first_provider = create provider_name
      first_user = create :user, institution: first_provider.institution
      create :identity, provider: first_provider, user: first_user

      second_provider = create provider_name
      second_user = build :user, email: first_user.email, institution: second_provider.institution
      second_identity = build :identity, provider: second_provider, user: second_user
      omniauth_mock_identity second_identity

      assert_difference 'User.count', 0 do
        get omniauth_url(second_provider)
        follow_redirect!
      end

      assert_redirected_to root_path
      assert_nil @controller.current_user
      assert_not_equal first_user.reload.username, second_user.username
    end
  end

  test 'login with temporary user should convert them to normal' do
    OAUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name
      user = create :temporary_user
      identity = build :identity, provider: provider, user: user
      username = 'real_username'
      omniauth_mock_identity identity,
                             uid: username

      # Call the authorization url.
      get omniauth_url(provider)
      follow_redirect!

      # Assert user has been updated.
      user.reload
      assert_equal user, @controller.current_user
      assert_equal 'real_username', user.username
      assert_equal provider.institution, user.institution

      # Sign-out and sign-in again.
      sign_out user

      omniauth_mock_identity identity, uid: username
      get omniauth_url(provider)
      follow_redirect!

      # Assert successful authentication.
      assert_equal user, @controller.current_user, 'temp user should be still able to sign in after conversion'

      # Cleanup.
      sign_out user
    end
  end

  test 'failure handler' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = build provider_name
      OmniAuth.config.mock_auth[:default] = :invalid_credentials

      # Call the authorization url.
      get omniauth_url(provider)
      follow_redirect!

      assert_redirected_to root_path
      assert_nil @controller.current_user
    end
  end

  test 'oauth login with missing provider' do
    OAUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = build provider_name, identifier: nil
      user = build :user, institution: provider.institution
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      get omniauth_url(provider)
      follow_redirect!

      # Assert failed authentication.
      assert_redirected_to sign_in_path
      assert_nil @controller.current_user
    end
  end
end
