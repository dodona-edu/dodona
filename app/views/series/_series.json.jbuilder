json.extract! series,
              :id,
              :name,
              :description,
              :visibility,
              :visibility_start,
              :order,
              :created_at,
              :updated_at,
              :deadline
json.url series_url(series, format: :json)
json.course course_url(series.course, format: :json)
json.exercises series_activities_url(series, format: :json)
