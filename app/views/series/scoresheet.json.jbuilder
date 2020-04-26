json.array! @users do |user|
  json.extract! user, :id, :username, :full_name, :email
  json.exercises do
    json.array! @activities do |activity|
      json.extract! activity, :id, :name
      if activity.exercise?
        json.accepted @submissions[[user.id, activity.id]]&.accepted || false
        json.status @submissions[[user.id, activity.id]]&.status || 'unstarted'
      elsif activity.content_page?
        json.accepted @read_states[[user.id, activity.id]].present?
        json.status @read_states[[user.id, activity.id]].present? ? 'read' : 'unread'
      end
    end
  end
end
