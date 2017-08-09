module ExerciseHelper
  def exercise_anchor(exercise)
    '#'.concat exercise_anchor_id(exercise)
  end

  def exercise_anchor_id(exercise)
    "exercise-#{exercise.id}"
  end
end
