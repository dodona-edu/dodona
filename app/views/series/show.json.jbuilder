json.partial! 'series/series', series: @series
json.exercises @series.exercises do |exercise|
  json.extract! exercise, :id, :name
  json.url course_exercise_url(@series.course, exercise)
end
