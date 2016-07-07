json.array!(@courses) do |course|
  json.extract! course, :id, :name, :year, :secret, :open
  json.url course_url(course, format: :json)
end
