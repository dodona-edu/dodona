# == Schema Information
#
# Table name: review_users
#
#  id                :bigint           not null, primary key
#  review_session_id :bigint
#  user_id           :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class ReviewUser < ApplicationRecord
  belongs_to :user
  belongs_to :review_session
  has_many :reviews, dependent: :destroy
end
