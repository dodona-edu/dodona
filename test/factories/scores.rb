# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  rubric_id          :bigint           not null
#  feedback_id        :bigint           not null
#  score              :decimal(5, 2)
#  last_updated_by_id :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :score do
    score_item { nil }
    feedback { nil }
    score { '9.99' }
  end
end
