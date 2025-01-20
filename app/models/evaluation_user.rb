# == Schema Information
#
# Table name: evaluation_users
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  evaluation_id :bigint
#  user_id       :integer
#
# Indexes
#
#  index_evaluation_users_on_evaluation_id              (evaluation_id)
#  index_evaluation_users_on_user_id                    (user_id)
#  index_evaluation_users_on_user_id_and_evaluation_id  (user_id,evaluation_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (evaluation_id => evaluations.id)
#  fk_rails_...  (user_id => users.id)
#
class EvaluationUser < ApplicationRecord
  belongs_to :user
  belongs_to :evaluation
  has_many :feedbacks, dependent: :destroy
  validates :user_id, uniqueness: { scope: :evaluation_id }

  def score
    mapped = feedbacks.map(&:score).compact_blank
    mapped.sum if mapped.any?
  end

  def graded?
    mapped = feedbacks.map(&:score).compact_blank
    mapped.count > 0
  end

  def metadata
    {
      done: feedbacks.complete.count,
      total: feedbacks.count
    }
  end
end
