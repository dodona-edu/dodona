module DelayedJobHelper
  def assert_jobs_enqueued(number, &)
    assert_difference('Delayed::Job.count', number, &)
  end
end
