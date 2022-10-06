require 'test_helper'

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  def setup
    super
    # Caching is used in some login flows and should be active for the tests
    ActionController::Base.perform_caching = true
    Rails.cache = ActiveSupport::Cache::MemCacheStore.new
  end

  def teardown
    super
    ActionController::Base.perform_caching = false
    Rails.cache = ActiveSupport::Cache::NullStore.new
  end

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

    # LTI and SAML include the provider.
    auth_hash = auth_hash.deep_merge({ extra: { provider_id: identity.provider.id } }) if [Provider::Lti, Provider::Saml].include?(identity.provider.class)

    OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new(auth_hash)
  end

  def omniauth_url(provider)
    send(format('user_%<sym>s_omniauth_authorize_url', sym: provider.class.sym), provider: provider)
  end

  def omniauth_path(provider)
    send(format('user_%<sym>s_omniauth_authorize_path', sym: provider.class.sym), provider: provider)
  end

  test 'login with existing identity' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name
      user = create :user, institution: provider.institution
      identity = create :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      post omniauth_url(provider)
      follow_redirect!

      # Assert successful authentication.
      assert_redirected_to root_path
      assert_equal @controller.current_user, user

      # Cleanup.
      sign_out user
    end
  end

  test 'login with existing identity using secondary provider' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name, mode: :secondary, institution: create(:provider).institution
      user = create :user, institution: provider.institution
      identity = create :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      post omniauth_url(provider)
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
          post omniauth_url(provider)
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

  test 'login as a new user using secondary provider' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name, mode: :secondary, institution: create(:provider).institution
      user = build :user, institution: provider.institution
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      assert_difference 'User.count', 1 do
        assert_difference 'Identity.count', 1 do
          post omniauth_url(provider)
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
            post omniauth_url(provider)
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

    post omniauth_url(redirect_provider)
    follow_redirect!

    assert_redirected_to %r{/users/auth/#{preferred_provider.class.sym}/}
    assert_nil @controller.current_user
  end

  test 'login while already logged in should replace' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup #1.
      provider = create provider_name
      user = create :user, institution: provider.institution
      identity = create :identity, provider: provider, user: user

      # Authenticate #1.
      omniauth_mock_identity identity
      post omniauth_url(provider)
      follow_redirect!

      # Compare the id to the session since @controller.current_user is not
      # correct in this case (limitation of omniauth testing).
      assert_equal user.id, session['warden.user.user.key'][0][0]

      # Setup #2.
      provider2 = create provider_name
      user2 = create :user, institution: provider2.institution
      identity2 = create :identity, provider: provider2, user: user2

      # Authenticate #2.
      omniauth_mock_identity identity2
      post omniauth_url(provider2)
      follow_redirect!

      # Compare the id to the session since @controller.current_user is not
      # correct in this case (limitation of omniauth testing).
      assert_equal user2.id, session['warden.user.user.key'][0][0]

      # Cleanup.
      sign_out user2
    end
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

      post omniauth_url(provider)
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
      other_user = create :user, institution: provider.institution
      identity = create :identity, provider: provider, user: user

      omniauth_mock_identity identity,
                             info: {
                               email: other_user.email
                             }

      assert_emails 1 do
        post omniauth_url(provider)
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
      post omniauth_url(provider)
      follow_redirect!
    end

    assert_equal @controller.current_user.username, user.username
    assert_nil @controller.current_user.email
  end

  test 'login with a non-smartschool or lti provider without email should not work' do
    (AUTH_PROVIDERS - %i[lti_provider smartschool_provider]).each do |provider_name|
      provider = create provider_name
      user = build :user, email: nil, institution: provider.institution
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      assert_difference 'User.count', 0 do
        post omniauth_url(provider)
        follow_redirect!
      end

      assert_nil @controller.current_user

      # Cleanup.
      sign_out user
    end
  end

  test 'login with other institution should ask confirmation' do
    AUTH_PROVIDERS.each do |provider_name|
      first_provider = create provider_name
      first_user = create :user, institution: first_provider.institution
      create :identity, provider: first_provider, user: first_user

      second_provider = create provider_name
      second_user = build :user, email: first_user.email, institution: second_provider.institution
      second_identity = build :identity, provider: second_provider, user: second_user
      omniauth_mock_identity second_identity

      assert_difference 'User.count', 0 do
        post omniauth_url(second_provider)
        follow_redirect!
      end

      # Before confirm no one is signed in
      assert_redirected_to confirm_new_user_path
      assert_nil @controller.current_user
      assert_not_equal first_user.reload.username, second_user.username

      assert_difference 'User.count', 1 do
        post confirm_new_user_path
        follow_redirect!
      end

      # After confirm a new user is created
      assert_equal @controller.current_user.username, second_user.username
      assert_not_equal first_user.reload.username, second_user.username

      sign_out @controller.current_user
    end
  end

  test 'failure handler' do
    AUTH_PROVIDERS.each do |provider_name|
      # Setup.
      provider = create provider_name
      OmniAuth.config.mock_auth[:default] = :invalid_credentials

      # Call the authorization url.
      post omniauth_url(provider)
      follow_redirect!

      assert_redirected_to root_path
      assert_nil @controller.current_user
    end
  end

  test 'oauth login with missing provider' do
    %i[office365_provider smartschool_provider].each do |provider_name|
      # Setup.
      provider = build provider_name, identifier: nil
      user = build :user, institution: provider.institution
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      # Call the authorization url.
      post omniauth_url(provider)
      follow_redirect!

      # Assert failed authentication.
      assert_redirected_to root_path
      assert_nil @controller.current_user
    end
  end

  test 'Can sign up with personal account' do
    personal_providers = [
      create(:office365_provider, identifier: '9188040d-6c67-4c5b-b112-36a304b66dad', institution: nil),
      create(:gsuite_provider, identifier: nil, institution: nil)
    ]

    personal_providers.each do |provider|
      # Setup.
      user = build :user, institution: nil
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      assert_difference 'User.count', 1 do
        assert_difference 'Identity.count', 1 do
          # Call the authorization url.
          post omniauth_url(provider)
          follow_redirect!

          # assert privacy prompt before successful sign in
          assert_redirected_to privacy_prompt_path
          assert_nil @controller.current_user
          post privacy_prompt_path
        end
      end

      # Assert successful authentication.
      assert_redirected_to root_path
      assert_not_nil @controller.current_user
      assert_equal @controller.current_user.email, user.email
      assert_nil @controller.current_user.institution

      # Cleanup.
      sign_out user
    end
  end

  test 'No account is created if privacy statement is rejected' do
    personal_providers = [
      create(:office365_provider, identifier: '9188040d-6c67-4c5b-b112-36a304b66dad', institution: nil),
      create(:gsuite_provider, identifier: nil, institution: nil)
    ]

    personal_providers.each do |provider|
      # Setup.
      user = build :user, institution: nil
      identity = build :identity, provider: provider, user: user
      omniauth_mock_identity identity

      assert_difference 'User.count', 0 do
        assert_difference 'Identity.count', 0 do
          # Call the authorization url.
          post omniauth_url(provider)
          follow_redirect!

          # assert privacy prompt before successful sign in
          assert_redirected_to privacy_prompt_path
          assert_nil @controller.current_user
          get root_path # Decline privacy prompt
        end
      end

      # Assert unsuccessful authentication.
      assert_response :success
      assert_nil @controller.current_user
    end
  end

  test 'Office 365 identifier should be updated upon login if the identifier still used the old format' do
    # Setup.
    provider = create :office365_provider
    user = create :user, institution: provider.institution
    identity = create :identity, provider: provider, user: user, identifier: 'Foo.Bar', identifier_based_on_email: true
    omniauth_mock_identity identity,
                           info: {
                             email: 'Foo.Bar@test.com'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    assert_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user

    # sign in should still work with changed identifier
    omniauth_mock_identity identity,
                           info: {
                             email: 'Foo.Bar@test.com'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    # Assert successful authentication.
    assert_redirected_to root_path
    assert_equal @controller.current_user, user

    # Cleanup.
    sign_out user

    # Should not be able to change it again
    omniauth_mock_identity identity,
                           info: {
                             email: 'NEW-UID@test.com'
                           },
                           uid: 'NEWER-UID'

    post omniauth_url(provider)
    follow_redirect!

    # Assert successful authentication.
    assert_redirected_to root_path
    assert_not_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user
  end

  test 'Office 365 legacy sign in works with prefered username' do
    # Setup.
    provider = create :office365_provider
    user = create :user, institution: provider.institution
    identity = create :identity, provider: provider, user: user, identifier: 'Foo.Bar', identifier_based_on_email: true
    omniauth_mock_identity identity,
                           info: {
                             email: 'A.B@test.com'
                           },
                           extra: {
                             preferred_username: 'Foo.Bar@test.com'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    assert_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user
  end

  test 'Office 365 legacy sign in works with name' do
    # Setup.
    provider = create :office365_provider
    user = create :user, institution: provider.institution, first_name: 'Foo', last_name: 'Bar'
    identity = create :identity, provider: provider, user: user, identifier: 'X.Y', identifier_based_on_email: true
    omniauth_mock_identity identity,
                           info: {
                             email: 'A.B@test.com'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    assert_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user
  end

  test 'Smartschool identifier should be updated upon login if the identifier still used the old format' do
    # Setup.
    provider = create :smartschool_provider
    user = create :user, institution: provider.institution
    identity = create :identity, provider: provider, user: user, identifier: 'OLD-UID', identifier_based_on_username: true
    omniauth_mock_identity identity,
                           info: {
                             username: 'OLD-UID'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    assert_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user

    # sign in should still work with changed identifier
    omniauth_mock_identity identity,
                           info: {
                             username: 'OLD-UID'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    # Assert successful authentication.
    assert_redirected_to root_path
    assert_equal @controller.current_user, user

    # Cleanup.
    sign_out user

    # Should not be able to change it again
    omniauth_mock_identity identity,
                           info: {
                             username: 'NEW-UID'
                           },
                           uid: 'NEWER-UID'

    post omniauth_url(provider)
    follow_redirect!

    # Assert successful authentication.
    assert_redirected_to root_path
    assert_not_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user
  end

  test 'Smartschool legacy sign in works with email' do
    # Setup.
    provider = create :smartschool_provider
    user = create :user, institution: provider.institution, email: 'foo.bar@test.com'
    identity = create :identity, provider: provider, user: user, identifier: 'OLD-UID', identifier_based_on_username: true
    omniauth_mock_identity identity,
                           info: {
                             email: 'foo.bar@test.com',
                             username: 'NEW-USERNAME'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    assert_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user
  end

  test 'Smartschool legacy sign in works with name' do
    # Setup.
    provider = create :smartschool_provider
    user = create :user, institution: provider.institution, first_name: 'Foo', last_name: 'Bar'
    identity = create :identity, provider: provider, user: user, identifier: 'OLD-UID', identifier_based_on_username: true
    omniauth_mock_identity identity,
                           info: {
                             first_name: 'Foo',
                             last_name: 'Bar',
                             username: 'NEW-USERNAME'
                           },
                           uid: 'NEW-UID'

    post omniauth_url(provider)
    follow_redirect!

    assert_equal @controller.current_user, user
    identity.reload
    assert_equal identity.identifier, 'NEW-UID'

    # Cleanup.
    sign_out user
  end

  test 'Smartschool co-accounts should be blocked' do
    # Setup.
    provider = create :smartschool_provider
    user = create :user, institution: provider.institution
    identity = create :identity, provider: provider, user: user
    omniauth_mock_identity identity,
                           info: {
                             isCoAccount?: true
                           }

    post omniauth_url(provider)
    follow_redirect!

    assert_redirected_to root_path
    assert_nil @controller.current_user
  end

  test 'Smartschool main-accounts should not be blocked' do
    # Setup.
    provider = create :smartschool_provider
    user = create :user, institution: provider.institution
    identity = create :identity, provider: provider, user: user
    omniauth_mock_identity identity,
                           info: {
                             isCoAccount?: false
                           }

    post omniauth_url(provider)
    follow_redirect!

    assert_equal @controller.current_user, user
    # Cleanup.
    sign_out user
  end

  test 'lti redirects to main provider' do
    main_provider = create :provider
    provider = create :lti_provider, institution: main_provider.institution, mode: :link
    user = build :user, institution: provider.institution
    identity = build :identity, provider: provider, user: user
    omniauth_mock_identity identity

    # Test "inside iframe"
    post omniauth_url(provider)
    follow_redirect!
    assert_redirected_to lti_redirect_path(provider: main_provider.id, sym: main_provider.class.sym)

    # Test outside iframe
    post omniauth_url(provider)
    follow_redirect!(headers: {
      'Sec-Fetch-Dest' => 'document'
    })
    assert_redirected_to omniauth_url(main_provider)
  end

  test 'existing users can link new provider within institution' do
    institution = create :institution
    user = create :user, institution: institution, identities: []
    first_provider = create :provider, institution: institution, mode: :prefer, identities: []
    second_provider = create :provider, institution: institution, mode: :secondary, identities: []

    # Link user to first provider.
    first_identity = create :identity, provider: first_provider, user: user

    # Build, but don't save the identity for the second provider.
    # This allows us to log in with the second provider for the 'first' time.
    second_identity = build :identity, provider: second_provider, user: user
    omniauth_mock_identity second_identity

    # Simulate the user logging in with the second provider.
    # It should not create a user.
    assert_difference 'User.count', 0 do
      post omniauth_url(second_provider)
      follow_redirect!
    end

    # It should render the page where the user can choose.
    assert_response :success

    # It is actually the page we expect.
    assert_select 'h1', t('auth.redirect_to_known_provider.title')
    # The other provider is listed as a possibility.
    assert_select 'a.institution-sign-in' do |link|
      assert_equal omniauth_path(first_provider), link.attr('href').to_s
    end

    omniauth_mock_identity first_identity

    # The user listens to what we say and clicks the button.
    post omniauth_url(first_provider)
    follow_redirect!

    # It should have been linked.
    assert_redirected_to root_path
    assert_equal @controller.current_user, user

    user.identities.reload

    # The user should have two identities.
    assert_equal 2, user.identities.length

    # Done.
    sign_out user
  end
end
