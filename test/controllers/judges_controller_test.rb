require 'test_helper'

class JudgesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Judge, attrs: %i[name image renderer runner remote]

  setup do
    stub_git(Judge.any_instance)
    @instance = create :judge
    sign_in create(:zeus)
  end

  test_crud_actions
end
