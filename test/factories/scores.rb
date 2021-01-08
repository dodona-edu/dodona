# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  rubric_id          :bigint           not null
#  feedback_id        :bigint           not null
#  score              :decimal(5, 2)    not null
#  last_updated_by_id :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :score do
    feedback
    rubric { create :rubric, evaluation_exercise: feedback.evaluation_exercise }
    score { '6.00' }
    last_updated_by { create :user }
  end
end
