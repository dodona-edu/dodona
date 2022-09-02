if Rails.env.production? || Rails.env.staging?
  Datadog.configure do |c|
    c.tracing.instrument :rails, service_name: 'dodona'
    c.tracing.instrument :delayed_job
    c.tracing.instrument :dalli
    c.version = Dodona::Application::VERSION
  end
end
