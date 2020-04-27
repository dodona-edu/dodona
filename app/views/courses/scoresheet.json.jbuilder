json.array! @users do |user|
  json.extract! user, :id, :username, :full_name, :email
  json.series do
    json.array! @series do |series|
      json.extract! series, :id, :name
      json.total_activities series.activity_count
      json.completed_activities @hash[[user.id, series.id]][:accepted]
      json.started_activities @hash[[user.id, series.id]][:started]
    end
  end
end
