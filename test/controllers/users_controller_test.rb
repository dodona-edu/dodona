require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    @instance = create(:zeus)
    sign_in @instance
  end

  crud_helpers User, attrs: %i[username ugent_id first_name last_name email permission time_zone]
  test_crud_actions
end
