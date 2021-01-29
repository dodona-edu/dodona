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
class Score < ApplicationRecord
  attribute :score, :decimal
  # Used to detect conflicts
  attribute :expected_score, :decimal

  belongs_to :rubric
  belongs_to :feedback
  belongs_to :last_updated_by, class_name: 'User'

  def out_of_bounds?
    return false if score.nil?

    score < BigDecimal('0') || score > rubric.maximum
  end
end
