require 'test_helper'

class ApiTokensControllerControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers ApiToken, attrs: %i[description]

  setup do
    @instance = create :api_token
    sign_in @instance.user
  end

  # override CRUDTest's method, because url needs the user
  def create_request(attr_hash: nil)
    attr_hash ||= generate_attr_hash
    post user_api_tokens_url(:nl, @instance.user), params: model_params(attr_hash)
  end

  test_crud_actions only: %i[create destroy],
                    except: %i[create_redirect destroy_redirect]

  test 'should get index for user' do
    get user_api_tokens_url(:nl, @instance.user, @instance)
    assert_response :success
  end
end
