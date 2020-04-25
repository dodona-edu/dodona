json.array! @activities, partial: 'activities/activity', as: :activity, locals: { series: @series, course: @course }
