Datadog.configure do |c|
  c.use :rails, service_name: 'naos'
  c.use :delayed_job
  c.analytics_enabled = true
end