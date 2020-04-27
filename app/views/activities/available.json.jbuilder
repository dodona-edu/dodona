json.array! @activities, partial: 'activities/activity', as: :activity, locals: { course: @course, series: @series }
