require 'test_helper'

class JudgesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    stub_git(Judge.any_instance)
    @instance = create :judge
    sign_in create(:zeus)
  end

  crud_helpers Judge, attrs: %i[name image renderer runner remote]
  test_crud_actions only: %i[new create index]
end
