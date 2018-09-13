json.extract! series,
              :id,
              :name,
              :description,
              :visibility,
              :order,
              :created_at,
              :updated_at,
              :deadline
json.url series_url(series, format: :json)
json.exercises series_exercises_url(series, format: :json)
