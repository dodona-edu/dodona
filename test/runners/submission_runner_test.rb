
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
  end

  def docker_mock(out, err, status_code)
    obj = mock
    obj.stubs(:start)
    obj.stubs(:delete)
    obj.stubs(:attach).returns([out, err])
    obj.stubs(:wait).returns('StatusCode' => status_code)
    obj
  end

  test 'submission evaluation should start docker container' do
    submission = create :submission,
                        user: @user,
                        course: @course,
                        exercise: @exercise

    json = {
      accepted: true,
      status: :correct
    }.to_json
    Docker::Container.expects(:create).once.returns(docker_mock([json], '', 0))
    submission.evaluate
  end
end
