require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    @instance = create :submission
    sign_in create(:zeus)
  end

  test_crud_actions Submission,
                    attrs: %i[code exercise_id],
                    only: %i[index show create]
end
