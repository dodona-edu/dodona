json.array! @exercises, partial: 'exercises/exercise', as: :exercise, locals: { series: @series, course: @course }
