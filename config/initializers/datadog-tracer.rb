Datadog.configure do |c|
  c.use :rails, service_name: 'naos'
  c.analytics_enabled = true
end