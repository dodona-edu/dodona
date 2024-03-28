# == Schema Information
#
# Table name: evaluation_users
#
#  id            :bigint           not null, primary key
#  evaluation_id :bigint
#  user_id       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class EvaluationUser < ApplicationRecord
  belongs_to :user
  belongs_to :evaluation
  has_many :feedbacks, dependent: :destroy
  validates :user_id, uniqueness: { scope: :evaluation_id }

  def score
    mapped = feedbacks.map(&:score).filter(&:present?)
    mapped.sum if mapped.any?
  end

  def graded?
    mapped = feedbacks.map(&:score).filter(&:present?)
    mapped.count > 0
  end

  def metadata
    {
      done: feedbacks.complete.count,
      total: feedbacks.count
    }
  end
end
