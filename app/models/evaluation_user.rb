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

  def metadata
    {
      done: feedbacks.complete.count,
      total: feedbacks.count
    }
  end
end
