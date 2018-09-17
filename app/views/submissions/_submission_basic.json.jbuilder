json.extract! submission, :created_at, :status, :summary, :accepted, :id
json.url submission_url(submission, format: :json)
json.user user_url(submission.user, format: :json)
json.exercise exercise_url(submission.exercise, format: :json)
json.course course_url(submission.course, format: :json) if submission.course
