json.extract! @repository, :id, :name, :remote, :path, :judge_id, :created_at, :updated_at
json.url repository_url(@repository, format: :json)
