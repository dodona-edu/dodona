require 'test_helper'

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Repository, attrs: %i[name remote judge_id]

  setup do
    stub_git(Repository.any_instance)
    Repository.any_instance.stubs(:process_activities)
    @instance = create :repository
    @admin = create :zeus
    sign_in @admin
  end

  test_crud_actions

  test 'should process activities on create' do
    Repository.any_instance.expects(:process_activities)
    create_request_expect
  end

  test 'should reprocess activities' do
    Repository.any_instance.expects(:process_activities)
    get reprocess_repository_path(@instance)
    assert_redirected_to(@instance)
  end

  test 'should get public media' do
    @instance.stubs(:public_path).returns(Pathname.new('not-a-real-directory'))
    Repository.any_instance.stubs(:full_path).returns(Pathname.new('test/remotes/exercises'))
    get public_repository_url(@instance, 'CodersApprentice.png')

    assert_response :success
    assert_equal 'image/png', response.content_type
  end

  test 'should create repository admin on create' do
    assert_difference('RepositoryAdmin.count', 1, 'creating a repository should create a repository admin') do
      create_request
    end
  end

  test 'zeus and repository admin should be able to edit repository admins' do
    user = create :user

    assert_difference('@instance.admins.count', 1, 'zeus should always be able to add a repository admin') do
      post add_admin_repository_url(@instance, user_id: user.id)
    end

    sign_in user

    assert_difference('@instance.admins.count', 1, 'repo admin should be able to add a repository admin') do
      post add_admin_repository_url(@instance, user_id: @admin.id)
    end

    assert_difference('@instance.admins.count', -1, 'repo admin should be able to remove a repository admin') do
      post remove_admin_repository_url(@instance, user_id: @admin.id)
    end

    @instance.admins << (create :user)

    sign_in @admin

    assert_difference('@instance.admins.count', -1, 'zeus should be able to remove a repository admin') do
      post remove_admin_repository_url(@instance, user_id: user.id)
    end
  end

  test 'normal user should not be able to edit repository admins' do
    user = create :user
    repo_admin = create :user
    @instance.admins << repo_admin

    sign_in user

    @instance.admins << @admin

    assert_difference('@instance.admins.count', 0, 'user should not be able to remove a repository admin') do
      post remove_admin_repository_url(@instance, user_id: repo_admin.id)
    end

    assert_difference('@instance.admins.count', 0, 'user should not be able to add a repository admin') do
      post add_admin_repository_url(@instance, user_id: user.id)
    end
  end

  test 'last repository admin cannot be removed' do
    @instance.admins << @admin

    post remove_admin_repository_url(@instance, user_id: @admin.id)
    assert @instance.admins.include? @admin
  end

  test 'zeus and repository admin should be able to edit allowed courses' do
    course = create :course

    assert_difference('@instance.allowed_courses.count', 1, 'zeus should be able to add an allowed course') do
      post add_course_repository_url(@instance, course_id: course.id)
    end

    assert_difference('@instance.allowed_courses.count', -1, 'zeus should be able to remove an allowed course') do
      post remove_course_repository_url(@instance, course_id: course.id)
    end

    user = create :user
    @instance.admins << user

    sign_in user

    assert_difference('@instance.allowed_courses.count', 1, 'repository admin should be able to add an allowed course') do
      post add_course_repository_url(@instance, course_id: course.id)
    end

    assert_difference('@instance.allowed_courses.count', -1, 'repository admin should be able to remove an allowed course') do
      post remove_course_repository_url(@instance, course_id: course.id)
    end
  end

  test 'user should not be able to edit allowed courses' do
    course = create :course
    user = create :user

    sign_in user

    assert_difference('@instance.allowed_courses.count', 0, 'user should not be able to add an allowed course') do
      post add_course_repository_url(@instance, course_id: course.id)
    end

    @instance.allowed_courses << course

    assert_difference('@instance.allowed_courses.count', 0, 'user should not be able to remove an allowed course') do
      post remove_course_repository_url(@instance, course_id: course.id)
    end
  end
end

class RepositoryGitControllerTest < ActionDispatch::IntegrationTest
  # TODO: get rid of this duplication (models/repository_test.rb)
  setup do
    @remote = local_remote('exercises/echo')

    # allow pushing
    Rails.env.stubs(:production?).returns(true)
    @repository = create :repository, remote: @remote.path
    @repository.process_activities

    # update remote
    @remote.update_json('echo/config.json', 'make echo private') do |config|
      config.update 'access' => 'private'
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
    assert_equal 'private', find_echo.access
  end

  test 'should email during repository creation' do
    user = create :staff
    judge = create :judge, :git_stubbed
    sign_in user
    @remote.update_file('echo/config.json', 'break config') { '(╯°□°)╯︵ ┻━┻' }
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post repositories_path, params: { repository: { name: 'test', remote: @remote.path, judge_id: judge.id } }
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [user.email], email.to
  end

  test 'github webhook with commit info should update exercises' do
    commit_info = [{
      message: 'make echo private',
      author: {
        name: 'Deter Pawyndt',
        email: 'deter.pawyndt@ugent.be',
        username: 'dpawyndt'
      },
      committer: {
        name: 'Deter Pawyndt',
        email: 'deter.pawyndt@ugent.be',
        username: 'dpawyndt'
      },
      added: [],
      removed: [],
      modified: ['echo/config.json']
    }]
    post webhook_repository_path(@repository), params: { commits: commit_info }, headers: { "X-GitHub-Event": 'push' }
    assert_equal 'private', find_echo.access
  end

  test 'gitlab webhook with commit info should update exercises' do
    commit_info = [{
      message: 'make echo private',
      author: {
        name: 'Deter Pawyndt',
        email: 'deter.pawyndt@ugent.be',
        username: 'dpawyndt'
      },
      added: [],
      removed: [],
      modified: ['echo/config.json']
    }]
    post webhook_repository_path(@repository), params: { commits: commit_info }, headers: { "X-Gitlab-Event": 'push' }
    assert_equal 'private', find_echo.access
  end
end
