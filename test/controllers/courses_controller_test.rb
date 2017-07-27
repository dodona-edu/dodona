require 'helpers/crud_helper'
require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Course, attrs: %i[name year description]

  setup do
    @instance = create(:course)
    sign_in create(:zeus)
  end

  test_crud_actions
end
