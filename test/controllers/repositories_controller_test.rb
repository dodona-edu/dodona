require 'test_helper'

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    stub_git(Repository.any_instance)
    @instance = create :repository
    sign_in create(:zeus)
  end

  test_crud_actions Repository, attrs: %i[name remote judge]
end
