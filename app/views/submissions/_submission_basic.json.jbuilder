json.extract! submission, :created_at, :status, :summary, :accepted, :id
json.url submission_url(submission, format: :json)
json.user course_member_url(submission.course, submission.user, format: :json)
json.has_annotations submission.annotated?
json.exercise activity_url(submission.exercise, format: :json)
json.course course_url(submission.course, format: :json) if submission.course
