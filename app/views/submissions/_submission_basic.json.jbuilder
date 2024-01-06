json.extract! submission, :created_at, :status, :summary, :accepted, :id
json.url submission_url(submission, format: :json)
if submission.course.present?
  json.user course_member_url(submission.course, submission.user.id, format: :json)
else
  json.user user_url(submission.user.id, format: :json)
end
json.has_annotations submission.annotated?

if submission.course.nil?
  json.exercise activity_url(submission.exercise, format: :json)
else
  json.exercise course_activity_url(submission.course, submission.exercise, format: :json)
end

json.course course_url(submission.course, format: :json) if submission.course
