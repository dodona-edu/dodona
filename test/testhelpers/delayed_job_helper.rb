module DelayedJobHelper
  def assert_jobs_enqueued(number, &)
    assert_difference('Delayed::Job.count', number, &)
  end

  def with_delayed_jobs
    orig = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true
    yield
    Delayed::Worker.delay_jobs = orig
  end

  def run_delayed_jobs
    Delayed::Job.find_each(batch_size: 100) { |d| Delayed::Worker.new.run(d) }
  end
end
