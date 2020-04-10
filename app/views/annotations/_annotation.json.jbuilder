json.extract! annotation, :id, :line_nr, :annotation_text, :user_id, :submission_id, :created_at, :updated_at
json.rendered_markdown markdown(annotation.annotation_text)
json.submission_url submission_url(annotation.submission, format: :json)
json.url annotation_url(annotation, format: :json)
json.user do
  json.name annotation.user.full_name
  json.url user_url(annotation.user)
end
json.permission do
  json.update policy(annotation).update?
  json.destroy policy(annotation).destroy?
end
json.visibility do
  json.student policy(annotation).visible_student?
end
