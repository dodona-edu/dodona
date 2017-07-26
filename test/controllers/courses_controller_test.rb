require 'helpers/crud_helper'
require 'test_helper'

class CoursesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    @instance = create(:course)
    sign_in create(:zeus)
  end

  test_crud_actions Course, attrs: %i[name year description]
end
