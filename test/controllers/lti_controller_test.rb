require 'test_helper'

# In these tests we don't want to hit the network to get jwks content.
module LTI::JWK
  def get_jwks_content(_uri)
    LtiTestHelper.jwks_content
  end
end

class LtiControllerTest < ActionDispatch::IntegrationTest
  include LtiTestHelper
  include LtiHelper

  def setup
    super
    @provider = create(:lti_provider)
  end

  test 'content selection shows courses' do
    courses = create_list(:course, 2)
    payload = lti_payload('nonce', 'target', 'LtiDeepLinkingRequest')
    id_token = encode_jwt(payload)

    get content_selection_path, params: {
      id_token: id_token,
      provider_id: @provider.id
    }

    assert_response :ok
    courses.each do |course|
      assert_select 'option', course.name
    end
  end

  test 'content selection payload is correct' do
    series = create :series, exercise_count: 1
    payload = lti_payload('nonce', 'target', 'LtiDeepLinkingRequest')

    key = File.read(FILES_LOCATION.join('private_key.pem'))
    File.stubs(:file?).returns(true)
    File.stubs(:read).returns(key)

    post content_selection_path, params: {
      lti: {
        decoded_token: payload,
        activities: [series.exercises.first.id],
        series: series.id,
        course: series.course.id
      }
    }

    assert_response :ok
    encoded = JSON.parse(@response.body)['payload']
    decoded = decode_jwt(encoded)
    assert_equal @provider.client_id, decoded['iss']
    assert_equal @provider.issuer, decoded['aud']
    assert_equal 'nonce', decoded['nonce']
    assert_not_empty decoded['https://purl.imsglobal.org/spec/lti-dl/claim/data']
    items = decoded['https://purl.imsglobal.org/spec/lti-dl/claim/content_items']
    assert_equal [{
      'type' => 'ltiResourceLink',
      'title' => series.exercises.first.name,
      'url' => lti_activity_url(series.course.id, series.id, series.exercises.first)
    }], items
  end

  test 'missing kid is handled gracefully' do
    payload = lti_payload('nonce', 'target', 'LtiResourceLinkRequest')
    id_token = encode_jwt(payload)
    course = create :course

    # Change the kid in the original key, so we can simulate the rotation used by Ufora.
    LTI::JWK.module_eval do
      def get_jwks_content(_uri)
        LtiTestHelper.jwks_content('kid')
      end
    end

    get course_path course, id_token: id_token, provider_id: @provider.id
    assert_response :ok
    assert_not_empty flash[:error]

    # Restore the module
    LTI::JWK.module_eval do
      def get_jwks_content(_uri)
        LtiTestHelper.jwks_content
      end
    end
  end
end

class LtiFlowTest < ActionDispatch::IntegrationTest
  include LtiTestHelper

  def setup
    super
    @provider = create(:lti_provider)
    OmniAuth.config.test_mode = false
  end

  def teardown
    super
    OmniAuth.config.test_mode = true
  end

  # Test the "Launch Request" flow, where the is immediately logged in.
  test 'correct OpenID Connect Launch flow works' do
    target = 'http://www.example.com/target'
    # Described by section 5.1.1.1 of the IMS Security Framework.
    post '/users/auth/lti', params: {
      iss: @provider.issuer,
      login_hint: 'login hint test',
      target_link_uri: target
    }

    # Described by section 5.1.1.2 of the IMS Security Framework.
    assert_response :found
    location = URI.parse(@response.header['Location'])
    assert_equal @provider.authorization_uri, "#{location.scheme}://#{location.host}#{location.path}"
    params = URI.decode_www_form(location.query).to_h.symbolize_keys
    assert params[:scope].include? 'openid'
    assert_equal 'id_token', params[:response_type]
    assert_equal @provider.client_id, params[:client_id]
    assert_equal 'https://www.example.com/users/auth/lti/callback', params[:redirect_uri]
    assert_equal 'login hint test', params[:login_hint]
    assert_equal 'form_post', params[:response_mode]
    assert_equal 'none', params[:prompt]
    assert_not_empty params[:nonce]

    # Assume we have validated everything.
    # Create the JWT token we'll need to send to the tool.
    # Described in 5.1.1.3 of the IMS Security Framework.
    payload = lti_payload(params[:nonce], target, 'LtiResourceLinkRequest')
    id_token = encode_jwt(payload)

    # The LTI platform says OK, do the callback.
    # Described in section 5.1.1.3 of the IMS Security Framework
    post '/users/auth/lti/callback', params: {
      id_token: id_token,
      state: params[:state]
    }

    assert_response :found
    target_uri = URI.parse(@response.header['Location'])
    params = URI.decode_www_form(target_uri.query).to_h.symbolize_keys
    assert_equal target, "#{target_uri.scheme}://#{target_uri.host}#{target_uri.path}"
    assert_equal @provider.id.to_s, params[:provider_id]
    assert_not_empty params[:id_token]
  end

  test 'content selection is redirected even if target is wrong' do
    target = 'blip blop'

    post '/users/auth/lti', params: {
      iss: @provider.issuer,
      login_hint: 'login hint test',
      target_link_uri: target
    }

    assert_response :found
    location = URI.parse(@response.header['Location'])
    params = URI.decode_www_form(location.query).to_h.symbolize_keys

    payload = lti_payload(params[:nonce], target, 'LtiDeepLinkingRequest')
    id_token = encode_jwt(payload)

    post '/users/auth/lti/callback', params: {
      id_token: id_token,
      state: params[:state]
    }

    assert_response :redirect
    target_uri = URI.parse(@response.header['Location'])
    params = URI.decode_www_form(target_uri.query).to_h.symbolize_keys
    assert_equal content_selection_path, target_uri.path
    assert_equal @provider.id.to_s, params[:provider_id]
    assert_not_empty params[:id_token]
  end
end
