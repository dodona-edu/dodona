json.extract! submission, :created_at, :status, :summary, :accepted, :id
json.url submission_url(submission)
json.user do
  json.id submission.user_id
  json.url user_url(submission.user)
end
json.exercise do
  json.id submission.exercise_id
  json.url exercise_url(submission.exercise)
end
if submission.course
  json.course do
    json.id submission.course_id
    json.url course_url(submission.course)
  end
end
