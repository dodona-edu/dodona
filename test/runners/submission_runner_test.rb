
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

  test 'submission evaluation should start docker container' do
    submission = create :submission,
                        user: @user,
                        course: @course,
                        exercise: @exercise

    Docker::Container.expects(:create).once
    submission.evaluate
  end
end
