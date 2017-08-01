require 'test_helper'

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Repository, attrs: %i[name remote judge_id]

  setup do
    stub_git(Repository.any_instance)
    Repository.any_instance.stubs(:process_exercises)
    @instance = create :repository
    sign_in create(:zeus)
  end

  test_crud_actions

  test 'should process exercises on create' do
    Repository.any_instance.expects(:process_exercises)
    create_request_expect
  end

  test 'should reprocess exercises' do
    Repository.any_instance.expects(:process_exercises)
    get reprocess_repository_path(@instance)
    assert_redirected_to(@instance)
  end
end

class WebhookControllerTest < ActionDispatch::IntegrationTest
  # TODO: get rid of this duplication (models/repository_test.rb)
  def setup
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_exercises

    # update remote
    @remote.update_json('echo/config.json', 'make echo private') do |config|
      config.update 'visibility' => 'closed'
    end
  end

  def find_echo
    @repository.exercises.find_by(path: 'echo')
  end

  def teardown
    @remote.remove
    FileUtils.rmtree @repository.full_path if File.exist?(@repository.full_path)
  end

  test 'should update exercises without commit info' do
    post webhook_repository_path(@repository)
    assert_equal 'closed', find_echo.visibility
  end

  test 'should update exercises with commit info' do
    commit_info = [
      {
        message: 'make echo private',
        author: {
          name: 'Deter Pawyndt',
          email: 'deter.pawyndt@ugent.be',
          username: 'dpawyndt'
        },
        added: [],
        removed: [],
        modified: [
          'echo/config.json'
        ]
      }
    ]
    post webhook_repository_path(@repository), params: { commits: commit_info }
    assert_equal 'closed', find_echo.visibility
  end
end
