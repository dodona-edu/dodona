require 'test_helper'

class SeriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    @instance = create(:series)
    sign_in create(:zeus)
  end

  test_crud_actions Series, attrs: %i[name description course_id visibility order deadline]
end
