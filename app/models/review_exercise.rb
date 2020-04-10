# == Schema Information
#
# Table name: review_exercises
#
#  id                :bigint           not null, primary key
#  review_session_id :bigint
#  exercise_id       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class ReviewExercise < ApplicationRecord
  belongs_to :exercise
  belongs_to :review_session
  has_many :reviews, dependent: :destroy

  validates :exercise_id, presence: true
  validates :review_session_id, presence: true
end
