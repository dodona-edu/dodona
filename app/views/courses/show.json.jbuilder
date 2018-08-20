json.extract! @course, :id, :name, :teacher, :color, :year, :visibility, :registration, :created_at, :updated_at
json.series @series do |series|
  json.extract! series, :id, :name
  json.url series_url(series)
end
