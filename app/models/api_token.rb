# == Schema Information
#
# Table name: api_tokens
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  token       :string(255)
#  description :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ApiToken < ApplicationRecord
  belongs_to :user

  validates :description,
            presence: true,
            length: { minimum: 3, maximum: 255 },
            uniqueness: { scope: :user_id }

  def initialize(*params)
    super(*params)
    self.token = SecureRandom.urlsafe_base64(32) unless token
  end
end
