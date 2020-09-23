module DelayedJobHelper
  def assert_jobs_enqueued(number, &block)
    assert_difference('Delayed::Job.count', number, &block)
  end
end
