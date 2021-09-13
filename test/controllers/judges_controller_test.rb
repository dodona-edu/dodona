require 'test_helper'

class JudgesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Judge, attrs: %i[name image renderer remote]

  setup do
    stub_git(Judge.any_instance)
    @instance = create :judge
    sign_in users(:zeus)
  end

  test_crud_actions
end

class JudgesWebhookControllerTest < ActionDispatch::IntegrationTest
  setup do
    @remote = local_remote('judges/false')
    @judge = create :judge, remote: @remote.path
  end

  teardown do
    @remote.remove
    @judge.git_repository.remove
  end

  test 'webhook should update judge repository' do
    assert_difference('@judge.git_repository.commit_count', 1) do
      @remote.update_file('run', 'make judge work') do |_|
        [
          '#! /bin/bash',
          'true'
        ].join('\n')
      end
      post webhook_judge_path(@judge)
    end
  end
end
