Delayed::Worker.default_queue_name = 'default'

Delayed::Worker.queue_attributes = {
  default: { priority: 0 },
  low_priority_submissions: { priority: 10 },
  submissions: { priority: -1 },
  high_priority_submission: { priority: -10 },
}
