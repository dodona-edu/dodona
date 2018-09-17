module StubHelper
  # stub all git methods
  def stub_git(obj)
    obj.stubs(:pull)
    obj.stubs(:reset)
    obj.stubs(:clone_repo)
    obj.stubs(:repo_is_accessible).returns(true)
  end

  def stub_status(exercise, status)
    exercise.stubs(:status).returns(status)
    Exercise.statuses.keys.each do |key|
      exercise.stubs("#{key}?".to_sym).returns(key == status)
    end
  end

  refine FactoryBot::SyntaxRunner do
    include StubHelper
  end
end
