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
