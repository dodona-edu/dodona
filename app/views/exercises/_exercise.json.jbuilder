json.extract! exercise,
              :id,
              :name,
              :description_format,
              :boilerplate,
              :programming_language
if current_user
  json.last_solution_is_best exercise.best_is_last_submission?(current_user)
  json.has_solution exercise.last_submission(current_user).present?
  json.has_correct_solution exercise.last_correct_submission(current_user).present?
end
json.description exercise.description_localized
json.url exercise_scoped_url(exercise: exercise, series: series, course: course, options: {format: :json})
