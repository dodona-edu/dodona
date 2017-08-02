
require 'test_helper'
require 'timeout'

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

  def evaluate_with_stubbed_docker(obj = nil, **kwargs)
    obj = docker_mock(kwargs) unless obj
    Docker::Container.stubs(:create).returns(obj)
    @submission.evaluate
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
    obj.stubs(:attach).returns([[params[:output].to_json], [params[:err]]])
    obj.stubs(:wait).returns('StatusCode' => params[:status_code])
    obj
  end

  test 'submission evaluation should start docker container' do
    Docker::Container.expects(:create).once
    @submission.evaluate
  end

  test 'correct submission should be accepted' do
    evaluate_with_stubbed_docker
    assert @submission.accepted
  end

  test 'correct submission should be correct' do
    evaluate_with_stubbed_docker
    assert_equal 'correct', @submission.status
  end

  test 'docker container should be deleted after use' do
    docker = docker_mock
    docker.expects(:delete)
    evaluate_with_stubbed_docker(docker)
  end

  test 'malformed json should result in internal error' do
    docker = docker_mock
    docker.stubs(:attach).returns([['DIKKE TAARTEN'], ['']])
    result = evaluate_with_stubbed_docker(docker)
    assert_equal 'internal error', result['status']
  end

  test 'non-zero status code should result in internal error' do
    result = evaluate_with_stubbed_docker status_code: 1
    assert_equal 'internal error', result['status']
  end

  test 'timeout should exceeded time limit' do
    Timeout.stubs(:timeout).raises(Timeout::Error)
    result = evaluate_with_stubbed_docker
    assert_equal 'time limit exceeded', result['status']
  end
end
