json.extract! submission, :created_at, :status, :summary, :accepted, :id
json.url submission_url(submission, format: :json)
json.user course_member_url(course_id: submission.course, id: submission.user.id, format: :json) if submission.course
json.has_annotations submission.annotated?
json.exercise activity_url(submission.exercise, format: :json)
json.course course_url(submission.course, format: :json) if submission.course
