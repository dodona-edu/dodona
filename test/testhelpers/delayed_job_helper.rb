module DelayedJobHelper
  def assert_jobs_enqueued(number)
    assert_difference('Delayed::Job.count', number) do
      yield
    end
  end
end
