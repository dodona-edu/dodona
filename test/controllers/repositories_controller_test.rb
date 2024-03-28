require 'test_helper'

class RepositoriesControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest

  crud_helpers Repository, attrs: %i[name remote judge_id]

  setup do
    stub_git(Repository.any_instance)
    Repository.any_instance.stubs(:process_activities)
    @instance = create :repository
    Repository.any_instance.stubs(:full_path).returns(Pathname.new('test/remotes/exercises/echo'))
    @admin = users(:zeus)
    sign_in @admin
  end

  def test_request_public_image
    get public_repository_url(@instance, 'CodersApprentice.png'), headers: { range: 'bytes=150-300' }

    assert_response :success
    assert_equal 'image/png', response.content_type
    assert_equal 151, response.content_length
    assert_equal 'bytes', response.headers['accept-ranges']
  end

  test_crud_actions

  test 'should reprocess activities' do
    Repository.any_instance.expects(:process_activities)
    get reprocess_repository_path(@instance)

    assert_redirected_to(@instance)
  end

  test 'should reprocess activities on judge change' do
    Repository.any_instance.expects(:process_activities)
    patch repository_path(@instance), params: { repository: { judge_id: create(:judge, :git_stubbed).id } }

    assert_redirected_to(@instance)
  end

  test 'should get public media' do
    test_request_public_image
  end

  test 'public media should be public' do
    sign_out @admin
    test_request_public_image
  end

  test 'should create repository admin on create' do
    assert_difference('RepositoryAdmin.count', 1, 'creating a repository should create a repository admin') do
      create_request
    end
  end

  test 'zeus and repository admin should be able to edit repository admins' do
    user = users(:student)

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
    user = users(:student)
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

    assert_includes @instance.admins, @admin
  end

  test 'allowed courses should render' do
    course = courses(:course1)
    @instance.allowed_courses << course
    get courses_repository_url(@instance)

    assert_response :success
    user = users(:student)
    @instance.admins << user
    get courses_repository_url(@instance)

    assert_response :success
  end

  test 'zeus and repository admin should be able to edit allowed courses' do
    course = courses(:course1)

    assert_difference('@instance.allowed_courses.count', 1, 'zeus should be able to add an allowed course') do
      post add_course_repository_url(@instance, course_id: course.id)
    end

    assert_difference('@instance.allowed_courses.count', -1, 'zeus should be able to remove an allowed course') do
      post remove_course_repository_url(@instance, course_id: course.id)
    end

    user = users(:student)
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
    course = courses(:course1)
    user = users(:student)

    sign_in user

    assert_difference('@instance.allowed_courses.count', 0, 'user should not be able to add an allowed course') do
      post add_course_repository_url(@instance, course_id: course.id)
    end

    @instance.allowed_courses << course

    assert_difference('@instance.allowed_courses.count', 0, 'user should not be able to remove an allowed course') do
      post remove_course_repository_url(@instance, course_id: course.id)
    end
  end

  test 'only zeus should be able to edit featured' do
    f = !@instance.featured
    patch repository_path(@instance), params: { repository: { featured: f }, format: :json }

    assert_response :success
    @instance.reload

    assert_equal f, @instance.featured

    sign_out @admin
    user = users(:staff)
    @instance.admins << user
    sign_in user

    f = !@instance.featured
    patch repository_path(@instance), params: { repository: { featured: f }, format: :json }
    @instance.reload

    assert_not_equal f, @instance.featured

    sign_out user
    sign_in @admin
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

    @second_remote = local_remote('exercises/lasagna')
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

  test 'should process activities on create' do
    Repository.any_instance.expects(:process_activities)
    user = users(:staff)
    judge = create :judge, :git_stubbed
    sign_in user
    post repositories_path, params: { repository: { name: 'test', remote: @second_remote.path, judge_id: judge.id } }
  end

  test 'should email during repository creation' do
    user = users(:staff)
    judge = create :judge, :git_stubbed
    sign_in user
    @second_remote.update_file('exercises/extra/echo/config.json', 'break config') { '(╯°□°)╯︵ ┻━┻' }
    assert_difference 'ActionMailer::Base.deliveries.size', +1 do
      post repositories_path, params: { repository: { name: 'test', remote: @second_remote.path, judge_id: judge.id } }
    end
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
    post webhook_repository_path(@repository), params: { commits: commit_info }, headers: { 'X-GitHub-Event': 'push' }

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
    post webhook_repository_path(@repository), params: { commits: commit_info }, headers: { 'X-Gitlab-Event': 'push' }

    assert_equal 'private', find_echo.access
  end

  test 'github webhook with incorrect commit should email pusher' do
    @remote.write_file('dirconfig.json', 'Write invalid config') do
      '{"invalid json",,}'
    end
    params = {
      commits: [{
        committer: {
          name: 'Deter Pawyndt',
          email: 'deter.pawyndt@ugent.be',
          username: 'dpawyndt'
        },
        message: 'Write invalid config',
        added: ['{"invalid json",,}'],
        removed: [],
        modified: ['dirconfig.json']
      }],
      pusher: {
        name: 'Deter Pawyndt',
        email: 'a@ugent.be',
        username: 'dpawyndt'
      }
    }
    post webhook_repository_path(@repository), params: params, headers: { 'X-GitHub-Event': 'push' }

    email = ActionMailer::Base.deliveries.last

    assert_equal ['a@ugent.be'], email.to
  end

  test 'gitlab webhook with incorrect commit should email pusher' do
    @remote.write_file('dirconfig.json', 'Write invalid config') do
      '{"invalid json",,}'
    end
    params = {
      commits: [{
        message: 'Write invalid config',
        added: ['{"invalid json",,}'],
        removed: [],
        modified: ['dirconfig.json']
      }],
      user_name: 'Deter Pawyndt',
      user_email: 'a@ugent.be'
    }
    post webhook_repository_path(@repository), params: params, headers: { 'X-Gitlab-Event': 'push' }

    email = ActionMailer::Base.deliveries.last

    assert_equal ['a@ugent.be'], email.to
  end

  test 'github webhook with incorrect commit should email first admin when no mail is present' do
    user = users(:staff)
    @repository.admins << user
    @remote.write_file('dirconfig.json', 'Write invalid config') do
      '{"invalid json",,}'
    end
    params = {
      commits: [{
        committer: {
          name: 'Deter Pawyndt',
          email: 'deter.pawyndt@ugent.be',
          username: 'dpawyndt'
        },
        message: 'Write invalid config',
        added: ['{"invalid json",,}'],
        removed: [],
        modified: ['dirconfig.json']
      }],
      pusher: {
        name: 'Deter Pawyndt',
        username: 'dpawyndt'
      }
    }
    post webhook_repository_path(@repository), params: params, headers: { 'X-GitHub-Event': 'push' }

    email = ActionMailer::Base.deliveries.last

    assert_equal [user.email], email.to
  end

  test 'github webhook with incorrect commit should email first admin when no mail is invalid' do
    user = users(:staff)
    @repository.admins << user
    @remote.write_file('dirconfig.json', 'Write invalid config') do
      '{"invalid json",,}'
    end
    params = {
      commits: [{
        committer: {
          name: 'Deter Pawyndt',
          email: 'deter.pawyndt@ugent.be',
          username: 'dpawyndt'
        },
        message: 'Write invalid config',
        added: ['{"invalid json",,}'],
        removed: [],
        modified: ['dirconfig.json']
      }],
      pusher: {
        name: 'Deter Pawyndt',
        email: 'a.ugent.be',
        username: 'dpawyndt'
      }
    }
    post webhook_repository_path(@repository), params: params, headers: { 'X-GitHub-Event': 'push' }

    email = ActionMailer::Base.deliveries.last

    assert_equal [user.email], email.to
  end

  test 'gitlab webhook with incorrect commit should email first admin when no mail is present' do
    user = users(:staff)
    @repository.admins << user
    @remote.write_file('dirconfig.json', 'Write invalid config') do
      '{"invalid json",,}'
    end
    params = {
      commits: [{
        committer: {
          name: 'Deter Pawyndt',
          email: 'deter.pawyndt@ugent.be',
          username: 'dpawyndt'
        },
        message: 'Write invalid config',
        added: ['{"invalid json",,}'],
        removed: [],
        modified: ['dirconfig.json']
      }],
      user_name: 'Deter Pawyndt'
    }
    post webhook_repository_path(@repository), params: params, headers: { 'X-Gitlab-Event': 'push' }

    email = ActionMailer::Base.deliveries.last

    assert_equal [user.email], email.to
  end

  test 'gitlab webhook with incorrect commit should email first admin when no mail is invalid' do
    user = users(:staff)
    @repository.admins << user
    @remote.write_file('dirconfig.json', 'Write invalid config') do
      '{"invalid json",,}'
    end
    params = {
      commits: [{
        committer: {
          name: 'Deter Pawyndt',
          email: 'deter.pawyndt@ugent.be',
          username: 'dpawyndt'
        },
        message: 'Write invalid config',
        added: ['{"invalid json",,}'],
        removed: [],
        modified: ['dirconfig.json']
      }],
      user_name: 'Deter Pawyndt',
      user_email: 'a.ugent.be'
    }
    post webhook_repository_path(@repository), params: params, headers: { 'X-Gitlab-Event': 'push' }

    email = ActionMailer::Base.deliveries.last

    assert_equal [user.email], email.to
  end
end
