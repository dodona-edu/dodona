json.online_users @online_users
json.submissions_per_minute @submissions_per_minute
json.activities_being_worked_on @activities_being_worked_on&.each do |activity|
  json.extract! activity, :id, :name
  json.url course_activity_url(@course, activity)
  json.submission_count activity.submission_count
end
