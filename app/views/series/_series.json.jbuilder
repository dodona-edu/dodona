json.extract! series, :id, :course_id, :name, :description, :visibility, :order, :created_at, :updated_at, :deadline
json.url series_url(series, format: :json)
