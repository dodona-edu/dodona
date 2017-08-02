
require 'test_helper'

class SubmissionRunnerTest < ActiveSupport::TestCase
  setup do
    @repository = create :repository, :git_stubbed
    @judge = @repository.judge
    @course = create :course
    @user = create :user, courses: [@course]
    @series = create :series, course: @course
    @exercise = create :exercise,
                       series: [@series],
                       repository: @repository
    @submission = create :submission,
                         user: @user,
                         course: @course,
                         exercise: @exercise
  end

  def stub_docker(**params)
    Docker::Container.stubs(:create).returns(docker_mock(params))
  end

  def docker_mock(**params)
    default_params = {
      status_code: 0,
      output: {
        accepted: true,
        status: 'correct'
      }
    }

    params = default_params.merge(params)

    obj = mock
    obj.stubs(:start)
    obj.stubs(:delete)
    obj.stubs(:attach).returns([[params[:output]], [params[:err]]])
    obj.stubs(:wait).returns('StatusCode' => params[:status_code])
    obj
  end

  test 'submission evaluation should start docker container' do
    Docker::Container.expects(:create).once.returns(docker_mock)
    @submission.evaluate
  end

  test 'docker container should be deleted after use' do
    docker = docker_mock
    docker.expects(:delete)
    Docker::Container.stubs(:create).returns(docker)
    @submission.evaluate
  end
end
