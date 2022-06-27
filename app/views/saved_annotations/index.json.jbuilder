json.array! @saved_annotations do |saved_annotation|
  json.extract! saved_annotation, :id, :title, :annotation_text, :user_id, :exercise_id, :course_id, :created_at, :updated_at
  json.user do
    json.name saved_annotation.user.full_name
    json.url user_url(saved_annotation.user)
  end
  json.exercise do
    json.name saved_annotation.exercise.name
    json.url activity_url(saved_annotation.exercise)
  end
  json.course do
    json.name saved_annotation.course.name
    json.url course_url(saved_annotation.course)
  end
end
