json.extract! submission, :created_at, :status, :summary, :accepted, :id
json.url submission_url(submission, format: :json)
json.user user_url(submission.user, format: :json)
json.has_annotations submission.annotated?
json.exercise activity_url(submission.activity, format: :json)
json.course course_url(submission.course, format: :json) if submission.course
