json.array!(@labels) do |label|
  json.extract! label, :id, :name, :color
  json.url label_url(label, format: :json)
end
