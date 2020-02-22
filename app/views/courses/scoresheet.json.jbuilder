json.array! @users do |user|
  json.extract! user, :id, :username, :full_name, :email
  json.series do
    json.array! @series do |series|
      json.extract! series, :id, :name
      json.total_exercises series.exercises.count
      json.correct_exercises @hash[[user.id, series.id]]
    end
  end
end
