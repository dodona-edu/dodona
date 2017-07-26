require 'test_helper'

class JudgesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    stub_git(Judge.any_instance)
    @instance = create :judge
    sign_in create(:zeus)
  end

  test_crud_actions Judge, attrs: %i[name image renderer runner remote]
end
