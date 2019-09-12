json.extract! user,
              :id,
              :username,
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

json.subscribed_courses do
  json.array! user.subscribed_courses, partial: 'courses/course', as: :course
end
