# == Schema Information
#
# Table name: feedbacks
#
#  id                     :bigint           not null, primary key
#  submission_id          :integer
#  evaluation_id          :bigint
#  evaluation_user_id     :bigint
#  evaluation_exercise_id :bigint
#  completed              :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
FactoryBot.define do
  factory :feedback do
    submission
    evaluation
    completed { false }
    evaluation_user { create :evaluation_user, evaluation: evaluation, user: submission.user }
    evaluation_exercise { create :evaluation_exercise, evaluation: evaluation, exercise: submission.exercise }
  end
end
