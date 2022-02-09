json.extract! activity,
              :id,
              :name,
              :type,
              :description_format
if activity.exercise?
  json.boilerplate activity.boilerplate
  json.programming_language activity.programming_language
  if current_user
    json.last_solution_is_best activity.best_is_last_submission?(current_user, series)
    json.has_solution activity.started_for?(current_user, series)
    json.has_correct_solution activity.solved_for?(current_user, series)
    json.accepted activity.accepted_for?(current_user, series)
    json.accepted_before_deadline activity.accepted_before_deadline_for?(current_user, series)
  end
elsif activity.content_page?
  json.has_read activity.solved_for?(current_user, series) if current_user
end
json.description_url description_activity_url(activity, token: activity.access_token)
json.url activity_scoped_url(activity: activity, series: series, course: course, options: { format: :json })
