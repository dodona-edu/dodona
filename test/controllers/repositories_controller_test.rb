require 'test_helper'

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Repository, attrs: %i[name remote judge_id]

  setup do
    stub_git(Repository.any_instance)
    Repository.any_instance.stubs(:process_exercises)
    @instance = create :repository
    @admin = create :zeus
    sign_in @admin
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

  test 'should create repository admin on create' do
    assert_difference('RepositoryAdmin.count', 1, "creating a repository should create a repository admin") do
      create_request
    end
  end

  test 'zeus and repository admin should be able to edit repository admins' do
    user = create :user

    assert_difference("@instance.admins.count", 1, "zeus should always be able to add a repository admin") do
      post add_admin_repository_url(@instance, user_id: user.id)
    end

    sign_in user

    assert_difference("@instance.admins.count", 1, "repo admin should be able to add a repository admin") do
      post add_admin_repository_url(@instance, user_id: @admin.id)
    end

    assert_difference("@instance.admins.count", -1, "repo admin should be able to remove a repository admin") do
      post remove_admin_repository_url(@instance, user_id: @admin.id)
    end

    user2 = create :user
    @instance.admins << user2

    sign_in @admin

    assert_difference("@instance.admins.count", -1, "zeus should be able to remove a repository admin") do
      post remove_admin_repository_url(@instance, user_id: user.id)
    end

    sign_in user

    @instance.admins << @admin

    assert_difference("@instance.admins.count", 0, "user should not be able to remove a repository admin") do
      post remove_admin_repository_url(@instance, user_id: user2.id)
    end

    assert_difference("@instance.admins.count", 0, "user should not be able to add a repository admin") do
      post add_admin_repository_url(@instance, user_id: user.id)
    end
  end

  test 'last repository admin cannot be removed' do
    @instance.admins << @admin

    post remove_admin_repository_url(@instance, user_id: @admin.id)
    assert @instance.admins.include? @admin
  end
end

class RepositoryWebhookControllerTest < ActionDispatch::IntegrationTest
  # TODO: get rid of this duplication (models/repository_test.rb)
  setup do
    @remote = local_remote('exercises/echo')

    # allow pushing
    Rails.env.stubs(:production?).returns(true)
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

  teardown do
    @remote.remove
    @repository.git_repository.remove
  end

  test 'webhook without commit info should update exercises' do
    post webhook_repository_path(@repository)
    assert_equal 'closed', find_echo.visibility
  end

  test 'webhook with commit info should update exercises' do
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
