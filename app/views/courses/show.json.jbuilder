json.extract! @course, :id, :name, :teacher, :color, :year, :visibility, :registration, :created_at, :updated_at
json.series course_series_index_url(@course, format: :json)
