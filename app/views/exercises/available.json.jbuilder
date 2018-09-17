json.array! @exercises, partial: 'exercises/exercise', as: :exercise, locals: { course: @course, series: @series }
