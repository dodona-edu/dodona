json.extract! @saved_annotation, :id, :title, :annotation_text, :user_id, :exercise_id, :course_id, :created_at, :updated_at
json.url saved_annotation_url(@saved_annotation)
