# == Schema Information
#
# Table name: evaluation_exercises
#
#  id            :bigint           not null, primary key
#  evaluation_id :bigint
#  exercise_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
require 'test_helper'

class EvaluationExerciseTest < ActiveSupport::TestCase
  test 'maximum score is correct' do
    exercise = create :evaluation_exercise
    r1 = create :score_item, maximum: '12.0', evaluation_exercise: exercise
    r2 = create :score_item, maximum: '5.0', evaluation_exercise: exercise

    assert exercise.maximum_score == r1.maximum + r2.maximum
  end
end
