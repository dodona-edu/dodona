Datadog.configure do |c|
  c.use :rails, service_name: 'dodona'
  c.use :delayed_job
  c.analytics_enabled = true
  c.version = Dodona::Application::VERSION
end
