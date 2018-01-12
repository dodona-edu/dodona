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

json.url user_url(user)
json.submission_count @user.submissions.count
json.correct_exercises @user.correct_exercises
