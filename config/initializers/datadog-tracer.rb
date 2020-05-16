if Rails.env.production? || Rails.env.staging?
  Datadog.configure do |c|
    c.use :rails, service_name: 'dodona'
    c.use :delayed_job
    c.use :dalli
    c.analytics_enabled = true
    c.version = Dodona::Application::VERSION
  end
end
