json.extract! @exercise, :id, :name, :description_format, :boilerplate, :file_name
json.description @exercise.description_localized
if current_user
  json.last_solution_correct @exercise.best_is_last_submission?(current_user)
  json.has_correct_solution @exercise.last_correct_submission(current_user).present?
end
