json.array!(@exercises) do |exercise|
  json.extract! exercise, :id, :name, :programming_language
  json.url exercise_url(exercise, format: :json)
end
