require 'test_helper'

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers ApiToken, attrs: %i[description]

  setup do
    @instance = create :api_token
    sign_in @instance.user
  end

  # override CRUDTest's method, because url needs the user
  def create_request(attr_hash: nil)
    attr_hash ||= generate_attr_hash
    post user_api_tokens_url(@instance.user), params: model_params(attr_hash)
  end

  test_crud_actions only: %i[create destroy],
                    except: %i[create_redirect destroy_redirect]

  test 'should get index for user' do
    get user_api_tokens_url(@instance.user), params: { format: :json }
    assert_response :success
  end

  test 'should not be able to create token for other user' do
    @other_user = create :user
    assert_difference('ApiToken.count', 0) do
      post user_api_tokens_url(:nl, @other_user), params: model_params(generate_attr_hash)
    end
    assert_equal flash[:alert], I18n.t('errors.models.api_token.attributes.not_permitted')
  end

  test 'should not be able to delete token from other user' do
    @other_user = create :user
    token = create :api_token, user: @other_user
    assert_difference('ApiToken.count', 0) do
      delete api_token_url(:nl, token)
    end
  end
end

class ApiTokensSignInTest < ActionDispatch::IntegrationTest
  setup do
    @user = create :user
    @token = create :api_token, user: @user
  end

  def fetch_root_with_token(token)
    token = token.token if token.instance_of?(ApiToken)
    get root_url, params: { format: :json },
                  headers: { 'Authorization' => token }
  end

  test 'should login with token' do
    fetch_root_with_token(@token)
    assert_response :success
    result = JSON.parse response.body
    assert_not_nil result['user']
    assert_equal result['user']['email'], @user.email
  end

  test 'should not login with wrong token' do
    fetch_root_with_token('Not a correct token')
    assert_response :unauthorized
  end
end
