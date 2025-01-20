# == Schema Information
#
# Table name: scores
#
#  id                 :bigint           not null, primary key
#  score              :decimal(5, 2)    not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  feedback_id        :bigint           not null
#  last_updated_by_id :integer          not null
#  score_item_id      :bigint           not null
#
# Indexes
#
#  index_scores_on_feedback_id                    (feedback_id)
#  index_scores_on_last_updated_by_id             (last_updated_by_id)
#  index_scores_on_score_item_id                  (score_item_id)
#  index_scores_on_score_item_id_and_feedback_id  (score_item_id,feedback_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (feedback_id => feedbacks.id)
#  fk_rails_...  (last_updated_by_id => users.id)
#  fk_rails_...  (score_item_id => score_items.id)
#
FactoryBot.define do
  factory :score do
    score { '6.00' }
    last_updated_by { User.find(3) } # load student fixture
  end
end
