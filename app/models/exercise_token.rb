# == Schema Information
#
# Table name: exercise_tokens
#
#  id          :integer          not null, primary key
#  token       :string(255)
#  exercise_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'securerandom'

class ExerciseToken < ApplicationRecord
  belongs_to :exercise

  before_create :generate_token

  def generate_token
    self.token = SecureRandom.urlsafe_base64(15)
  end
end
