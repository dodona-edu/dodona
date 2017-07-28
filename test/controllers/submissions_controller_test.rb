require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Submission, attrs: %i[code exercise_id]

  setup do
    @instance = create :submission
    sign_in create(:zeus)
  end

  test_crud_actions only: %i[index show create], except: %i[create_redirect]

  test 'should add submissions to delayed_job queue' do
    assert_jobs_enqueued(1) do
      create_request
    end
  end

  test 'create submission should respond with ok' do
    create_request_expect
    assert_response :success
  end
end
