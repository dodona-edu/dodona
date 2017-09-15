module StubHelper
  # stub all git methods
  def stub_git(obj)
    obj.stubs(:pull)
    obj.stubs(:reset)
    obj.stubs(:clone_repo)
    obj.stubs(:repo_is_accessible).returns(true)
  end

  refine FactoryGirl::SyntaxRunner do
    include StubHelper
  end
end
