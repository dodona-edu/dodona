require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers User, attrs: %i[username ugent_id first_name last_name email permission time_zone]

  setup do
    @instance = create(:zeus)
    sign_in @instance
  end

  test_crud_actions
end
