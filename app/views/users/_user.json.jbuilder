json.extract! user,
              :id,
              :username,
              :ugent_id,
              :first_name,
              :last_name,
              :email,
              :permission,
              :time_zone,
              :lang

json.url user_url(user, format: :json)
json.submissions user_submissions_url(user, format: :json)
json.submission_count user.submissions.count
json.correct_exercises user.correct_exercises

json.subscribed_courses user.subscribed_courses do |course|
  json.extract! course, :id, :name, :year, :teacher, :color
  json.url course_url(course, format: :json)
end
