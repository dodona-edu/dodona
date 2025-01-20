# == Schema Information
#
# Table name: evaluation_exercises
#
#  id            :bigint           not null, primary key
#  visible_score :boolean          default(TRUE), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  evaluation_id :bigint
#  exercise_id   :integer
#
# Indexes
#
#  index_evaluation_exercises_on_evaluation_id                  (evaluation_id)
#  index_evaluation_exercises_on_exercise_id                    (exercise_id)
#  index_evaluation_exercises_on_exercise_id_and_evaluation_id  (exercise_id,evaluation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (evaluation_id => evaluations.id)
#  fk_rails_...  (exercise_id => activities.id)
#
FactoryBot.define do
  factory :evaluation_exercise do
    exercise
    evaluation
  end
end
