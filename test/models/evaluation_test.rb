# == Schema Information
#
# Table name: evaluations
#
#  id         :bigint           not null, primary key
#  series_id  :integer
#  released   :boolean          default(FALSE), not null
#  deadline   :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'test_helper'

class EvaluationTest < ActiveSupport::TestCase
  test 'maximum score is correct' do
    evaluation = create :evaluation, :with_submissions
    exercises = evaluation.evaluation_exercises
    r1 = create :score_item, maximum: '12.0', evaluation_exercise: exercises.first
    r2 = create :score_item, maximum: '5.0', evaluation_exercise: exercises.first
    r3 = create :score_item, maximum: '7.0', evaluation_exercise: exercises[1]

    assert evaluation.maximum_score == r1.maximum + r2.maximum + r3.maximum
  end
end
