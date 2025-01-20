# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  score_item_id      :bigint           not null
#  feedback_id        :bigint           not null
#  score              :decimal(5, 2)    not null
#  last_updated_by_id :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
FactoryBot.define do
  factory :score do
    score { '6.00' }
    last_updated_by { User.find(3) } # load student fixture
  end
end
