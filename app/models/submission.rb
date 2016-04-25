# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  exercise_id :integer
#  user_id     :integer
#  code        :text(65535)
#  result      :integer          default("0")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Submission < ApplicationRecord
  belongs_to :exercise
  belongs_to :user

  scope :of_user, ->(user) { where user_id: user.id }
end
