# If a submission delayed job fails: set the status to failed and add log
# https://www.rubydoc.info/github/collectiveidea/delayed_job/Delayed/Lifecycle
# rubocop:disable SuppressedException
class SubmissionDjPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:perform) do |_worker, _job, *_args|
      ActivityStatus.clear_status_store
    end
    lifecycle.after(:failure) do |_worker, job, *_args|
      if job.payload_object.object.is_a?(Submission)
        sub = job.payload_object.object
        Delayed::Worker.logger.debug("Failed submission #{sub.id} by user #{sub.user_id} for exercise #{sub.exercise_id} after #{job.attempts} attempts (worker #{job.locked_by})")
        Delayed::Worker.logger.debug(job.last_error[0..10_000])
        begin
          sub.save_result(
            accepted: false,
            status: 'internal error',
            description: 'Dodona Error',
            messages: [
              { 'format' => 'plain', 'description' => 'Delayed job failed, due to a very unexpected error.', 'permission' => 'staff' },
              { 'format' => 'code', 'description' => job.last_error[0..10_000], 'permission' => 'staff' }
            ]
          )
        rescue StandardError
          sub.update(status: :'internal error', summary: 'failed to save result', accepted: false)
        end
        Delayed::Worker.logger.debug("Set failed status on submission #{sub.id}")
      elsif job.payload_object.object.is_a?(Export)
        job.payload_object.object.update(status: :failed)
      end
      ExceptionNotifier.notify_exception(Exception.new("Delayed job failure: #{job.last_error.split("\n").first}"), data: { worker: `hostname`, queue: job.queue, payload: job.payload_object, last_error: job.last_error })
    rescue StandardError
      # This must not fail in any case.
      # Raising an error kills the worker.
    end
  end
end
# rubocop:enable SuppressedException

Rails.application.configure do
  config.after_initialize do
    Delayed::Worker.destroy_failed_jobs = false # Keep failed jobs for logging
    Delayed::Worker.sleep_delay = 5 # seconds sleep if no job, default 5
    Delayed::Worker.max_attempts = 3 # default is 25
    Delayed::Worker.max_run_time = 2.hours
    Delayed::Worker.read_ahead = 2 # default is 5
    Delayed::Worker.raise_signal_exceptions = :term # on kill release job
    Delayed::Worker.logger = Logger.new(Rails.root.join('log/delayed_job.log'))
    Delayed::Worker.default_queue_name = 'default'
    Delayed::Worker.queue_attributes = {
      default: { priority: 0 },
      statistics: { priority: 10 },
      exports: { priority: 20 },
      low_priority_submissions: { priority: 10 },
      submissions: { priority: 0 },
      high_priority_submission: { priority: -10 }
    }
    Delayed::Worker.plugins << SubmissionDjPlugin

    Delayed::Backend::ActiveRecord.configure do |config|
      config.reserve_sql_strategy = :default_sql
    end
  end
end
