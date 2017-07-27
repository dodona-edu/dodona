require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  setup do
    @instance = create :submission
    sign_in create(:zeus)
  end

  crud_helpers Submission, attrs: %i[code exercise_id]

  test_crud_actions only: %i[index show create]

  test 'should add submissions to delayed_job queue' do
    assert_difference("Delayed::Job.count", +1) do
      create_request
    end
  end
end
