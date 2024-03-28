json.extract! annotation, :id, :line_nr, :annotation_text, :user_id, :submission_id, :created_at, :updated_at, :course_id, :column, :rows, :columns
json.row annotation.line_nr || 0
if annotation.is_a?(Question)
  json.extract! annotation, :question_state
  json.newer_submission_url(annotation.newer_submission&.then { |s| submission_url(s) })
end

json.rendered_markdown markdown(annotation.annotation_text)
json.submission_url submission_url(annotation.submission, format: :json)
json.url annotation_url(annotation, format: :json)

# hide reviewer name depending on evaluation and current user
unless policy(annotation).anonymous?
  json.user do
    json.name annotation.user.full_name
    json.url user_url(annotation.user)
  end
end
# hide name of last editor depending on evaluation and current user
unless policy(annotation).anonymous?
  json.last_updated_by do
    json.name annotation.last_updated_by.full_name
    json.url user_url(annotation.last_updated_by)
  end
end
json.permission do
  json.update policy(annotation).update?
  json.destroy policy(annotation).destroy?
  json.save SavedAnnotationPolicy.new(current_user, annotation).create?
  json.transition do
    Question.question_states.each_key do |state|
      json.set! state, policy(annotation).transition?(state)
    end
  end
  json.can_see_annotator !policy(annotation).anonymous?
end
json.released AnnotationPolicy.new(annotation.submission.user, annotation).show?
json.type annotation.type&.downcase

json.responses annotation.responses do |response|
  json.partial! response, as: :annotation
end
json.thread_root_id annotation.thread_root_id

# Only include the saved annotation id if the user is allowed to see it
json.saved_annotation_id annotation.saved_annotation_id if annotation.saved_annotation.present? && SavedAnnotationPolicy.new(current_user, annotation.saved_annotation).show?
