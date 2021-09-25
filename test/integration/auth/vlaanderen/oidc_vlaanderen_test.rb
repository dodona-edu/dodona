require 'test_helper'

###
# Tests the complete authentication flow for Vlaanderen (using OIDC).
#
# These tests have been written according to the technical specification provided below. Do not change these without
# consulting the documentation first.
# https://authenticatie.vlaanderen.be/docs/beveiligen-van-toepassingen/integratie-methoden/oidc/technische-info/aanmelden/
# https://authenticatie.vlaanderen.be/docs/beveiligen-van-toepassingen/integratie-methoden/oidc/technische-info/client-authenticatie/
# https://authenticatie.vlaanderen.be/docs/beveiligen-van-toepassingen/integratie-methoden/oidc/technische-info/discovery-url/
# https://authenticatie.vlaanderen.be/docs/beveiligen-van-toepassingen/integratie-methoden/oidc/technische-info/scope-claims/
###

# Set the signing key.
module OIDC::Auth::Settings
  private

  def private_key_path
    JwksHelper.private_key_path
  end
end

class AuthOIDCVlaanderenTest < ActionDispatch::IntegrationTest
  include JwksHelper

  ISSUER = 'https://authenticatie-ti.vlaanderen.be/op'.freeze
  AUTHORIZATION_URL = format('%s/v1/auth', ISSUER).freeze
  DISCOVERY_URL = format('%s/.well-known/openid-configuration', ISSUER).freeze
  KEYS_URL = format('%s/v1/keys', ISSUER).freeze
  KEY_ID = format('OIDC_VLAANDEREN_%d', Time.now.to_i).freeze
  TOKEN_URL = format('%s/v1/token', ISSUER).freeze

  def setup
    @provider = create :oidc_provider, issuer: ISSUER

    # Disable the test mode so that the whole flow is executed.
    OmniAuth.config.test_mode = false

    # Block all outbound calls, everything must be stubbed.
    WebMock.disallow_net_connect!
  end

  def teardown
    super
    OmniAuth.config.test_mode = true
    WebMock.allow_net_connect!
  end

  def omniauth_callback_url
    # Strip the trailing slash.
    user_oidc_omniauth_callback_url(locale: nil, protocol: 'https').to_s.chomp('/')
  end

  def omniauth_url(provider)
    user_oidc_omniauth_authorize_url(provider: provider)
  end

  def stub_discovery!
    # Load the saved discovery response.
    response = File.new Rails.root.join('test/integration/auth/vlaanderen/openid-configuration.json')
    stub_request(:get, DISCOVERY_URL).to_return(body: response, headers: { 'Content-Type': 'application/json' }, status: 200)
  end

  def stub_keys!(kid = nil)
    stub_request(:get, KEYS_URL).to_return(body: JwksHelper.jwks_content(kid), headers: { 'Content-Type': 'application/json' }, status: 200)
  end

  test 'should discover during request phase' do
    stub_discovery!

    # Call the redirect url.
    get omniauth_url(@provider)

    # Validate that discovery took place.
    assert_requested :get, DISCOVERY_URL
  end

  test 'should redirect to correct authorization url' do
    stub_discovery!

    # Call the redirect url.
    get omniauth_url(@provider)

    # Get the redirect url.
    assert_response :redirect
    redirect_url = URI.parse @response.redirect_url

    # Validate the base url.
    assert_equal AUTHORIZATION_URL, format('%<scheme>s://%<host>s%<path>s', { scheme: redirect_url.scheme, host: redirect_url.host, path: redirect_url.path })

    # Validate the parameters.
    parameters = CGI.parse(redirect_url.query).symbolize_keys

    # Client id must be equal to the one set in the provider.
    assert_equal @provider.client_id, parameters[:client_id].first

    # Nonce must not be empty.
    assert_not_empty parameters[:nonce].first

    # Redirect url must be equal to the callback url. This cannot contain any
    # parameters since it must be registered at the provider.
    assert_equal omniauth_callback_url, parameters[:redirect_uri].first

    # Response mode must be equal to "form_post" with the configured flow.
    assert_equal 'form_post', parameters[:response_mode].first

    # Response type must be equal to "code" at all times.
    assert_equal 'code', parameters[:response_type].first

    # Scope must contain openid and profile.
    assert_equal 'openid profile', parameters[:scope].first

    # State must not be empty and must start with the id of the provider so that
    # we can reconstruct this in the callback phase.
    assert_not_empty parameters[:state].first
    assert parameters[:state].first.to_s.start_with?(format('%s-', @provider.id))
  end

  test 'should handle the callback phase' do
    stub_discovery!
    stub_keys!(KEY_ID)

    # Call the redirect url to set the nonce and state.
    get omniauth_url(@provider)

    # Build an id token.
    id_token_body = {
      at_hash: Faker::Alphanumeric.alphanumeric,
      aud: @provider.client_id,
      azp: @provider.client_id,
      exp: Time.now.to_i + 3600,
      family_name: Faker::Name.last_name,
      given_name: Faker::Name.first_name,
      iat: Time.now.to_i,
      iss: ISSUER,
      kid: KEY_ID,
      nonce: session['omniauth.nonce'],
      sub: SecureRandom.uuid,
      vo_doelgroepcode: 'GID',
      vo_doelgroepnaam: 'VO-medewerkers',
      vo_email: Faker::Internet.email
    }
    id_token = encode_jwt id_token_body, KEY_ID

    # Stub the access token call.
    access_token_response = { access_token: Faker::Crypto.md5, expires_in: 3600, id_token: id_token, scope: 'profile', token_type: 'Bearer' }
    stub_request(:post, TOKEN_URL).to_return(body: access_token_response.to_json, headers: { 'Content-Type': 'application/json' }, status: 200)

    # Call the callback url.
    authorization_response = { code: Faker::Alphanumeric.alpha, state: session['omniauth.state'] }
    post omniauth_callback_url, params: authorization_response

    # Validate that discovery took place twice (once for request, once for callback).
    assert_requested :get, DISCOVERY_URL, times: 2

    # Validate that the JWKS keys were fetched.
    assert_requested :get, KEYS_URL

    # Validate that the access token request was made with the correct parameters.
    assert_requested(:post, TOKEN_URL, times: 1) do |at_req|
      # Validate the parameters.
      parameters = CGI.parse(at_req.body).symbolize_keys

      # Client assertion type must be equal to "urn:ietf:params:oauth:client-assertion-type:jwt-bearer".
      assert_equal 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer', parameters[:client_assertion_type].first

      # Client assertion must be a JWT with the correct client id and audience.
      client_assertion_encoded = parameters[:client_assertion].first
      assert_not_empty client_assertion_encoded
      client_assertion = decode_jwt(client_assertion_encoded).symbolize_keys
      assert_equal ISSUER, client_assertion[:aud]
      assert_equal @provider.client_id, client_assertion[:iss]
      assert_equal @provider.client_id, client_assertion[:sub]

      # Code must be equal to the code received from the provider.
      assert_equal authorization_response[:code], parameters[:code].first

      # Grant type must be equal to "authorization_code"
      assert_equal 'authorization_code', parameters[:grant_type].first
    end

    # Validate that the user is correctly logged in.
    current_user = @controller.current_user
    assert_equal id_token_body[:given_name], current_user.first_name
    assert_equal id_token_body[:family_name], current_user.last_name
    assert_equal id_token_body[:vo_email], current_user.email
  end
end
