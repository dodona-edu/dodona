json.extract! annotation, :id, :line_nr, :annotation_text, :created_at, :updated_at
json.user do
  json.name annotation.user.full_name
  json.url user_url(annotation.user)
end
json.permission do
  json.edit AnnotationPolicy.new(@current_user, annotation).update?
  json.delete AnnotationPolicy.new(@current_user, annotation).destroy?
end
json.markdown_text markdown(annotation.annotation_text)
json.submission_url submission_url(annotation.submission)
