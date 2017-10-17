json.array!(@tokens) do |token|
  json.extract! token, :id, :description, :created_at
  json.url api_token_url(token, format: :json)
end
