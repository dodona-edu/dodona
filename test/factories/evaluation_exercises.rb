# == Schema Information
#
# Table name: evaluation_exercises
#
#  id            :bigint           not null, primary key
#  evaluation_id :bigint
#  exercise_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  visible_score :boolean          default(TRUE), not null
#
FactoryBot.define do
  factory :evaluation_exercise do
    exercise
    evaluation
  end
end
