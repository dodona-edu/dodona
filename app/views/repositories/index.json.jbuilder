json.array!(@repositories) do |repository|
  json.extract! repository, :id, :name, :remote, :path, :judge_id
  json.url repository_url(repository, format: :json)
end
