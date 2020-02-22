json.array! @users do |user|
  json.extract! user, :id, :username, :full_name, :email
  json.exercises do
    json.array! @exercises do |exercise|
      json.extract! exercise, :id, :name
      json.accepted @submissions[[user.id, exercise.id]]&.accepted || false
      json.status @submissions[[user.id, exercise.id]]&.status || 'unstarted'
    end
  end
end
