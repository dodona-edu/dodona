require 'test_helper'

class InstitutionControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Institution, attrs: %i[name short_name]

  setup do
    @instance = create(:institution)
    sign_in create(:zeus)
  end

  test_crud_actions only: %i[index show]
end
