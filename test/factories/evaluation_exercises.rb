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
FactoryBot.define do
  factory :evaluation_exercise do
    exercise
    evaluation
  end
end
