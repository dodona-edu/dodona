json.extract! course, :id, :name, :description, :teacher, :color, :year, :visibility, :registration, :created_at, :updated_at
json.url course_url(course, format: :json)
json.series course_series_index_url(course, format: :json)
