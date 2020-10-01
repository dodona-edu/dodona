json.extract! annotation, :id, :line_nr, :annotation_text, :user_id, :submission_id, :created_at, :updated_at
json.extract! annotation, :question_state if annotation.is_a?(Question)
json.rendered_markdown markdown(annotation.annotation_text)
json.submission_url submission_url(annotation.submission, format: :json)
json.url annotation_url(annotation, format: :json)
json.user do
  json.name annotation.user.full_name
  json.url user_url(annotation.user)
end
json.last_updated_by do
  json.name annotation.last_updated_by.full_name
  json.url user_url(annotation.last_updated_by)
end
json.permission do
  json.update policy(annotation).update?
  json.destroy policy(annotation).destroy?
  json.transition do
    Question.question_states.each_key do |state|
      json.set! state, policy(annotation).transition?(state)
    end
  end
end
json.released AnnotationPolicy.new(annotation.submission.user, annotation).show?
json.type annotation.type&.downcase
