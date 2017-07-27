require 'helpers/crud_helper'
require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    @instance = create(:course)
    sign_in create(:zeus)
  end

  crud_helpers Course, attrs: %i[name year description]
  test_crud_actions
end
