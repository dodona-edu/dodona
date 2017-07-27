require 'test_helper'

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    stub_git(Repository.any_instance)
    Repository.any_instance.stubs(:process_exercises)
    @instance = create :repository
    sign_in create(:zeus)
  end

  test_crud_actions Repository, attrs: %i[name remote judge_id]
end
