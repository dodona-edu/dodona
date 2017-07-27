require 'test_helper'

class ExercisesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  def setup
    @instance = create(:exercise)
    sign_in create(:zeus)
  end

  test_crud_actions Exercise,
                    attrs: %i[visibility name_nl name_en],
                    only: %i[index edit update]

  test "should show exercise" do
    get exercise_url(@instance).concat('/')
    assert_response :success
  end
end
