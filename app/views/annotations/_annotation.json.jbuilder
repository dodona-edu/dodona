json.extract! annotation, :id, :line_nr, :annotation_text, :created_at, :updated_at
json.rendered_markdown markdown(annotation.annotation_text)
json.url annotation_url(annotation, format: :json)
json.user do
  json.name annotation.user.full_name
  json.url user_url(annotation.user)
end
json.permission do
  json.update policy(annotation).update?
  json.destroy policy(annotation).destroy?
end
