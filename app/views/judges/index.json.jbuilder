json.array!(@judges) do |judge|
  json.extract! judge, :id, :name, :image, :path
  json.url judge_url(judge, format: :json)
end
