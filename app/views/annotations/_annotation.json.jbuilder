json.extract! annotation, :id, :line_nr, :annotation_text, :user_id, :submission_id, :created_at, :updated_at
if annotation.is_a?(Question)
  json.extract! annotation, :question_state
  json.newer_submission_url(annotation.newer_submission&.then { |s| submission_url(s) })
end
json.rendered_markdown markdown(annotation.annotation_text)
json.submission_url submission_url(annotation.submission, format: :json)
json.url annotation_url(annotation, format: :json)
json.user do
  # if we are NOT an admin and the evaluation is anonymous and we are not the person that typed the annotation => hide name
  if !current_user.a_course_admin? && !annotation.evaluation.nil? && annotation.evaluation.anonymous? && (current_user.id != annotation.user.id)
    json.name 'Teacher'
  else
    json.name annotation.user.full_name
  end
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
