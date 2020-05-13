if current_user
  json.set! :user do
    json.partial! 'users/user', user: current_user
  end

  json.deadline_series @homepage_series do |series|
    json.partial! 'series/series', series: series
  end
end
json.version Dodona::Application::VERSION
json.min_supported_client Dodona::Application::MIN_SUPPORTED_CLIENT
