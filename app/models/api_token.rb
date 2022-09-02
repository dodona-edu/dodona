# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  user_id      :bigint
#  token_digest :string(255)
#  description  :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'digest'

class ApiToken < ApplicationRecord
  belongs_to :user

  validates :description,
            presence: true,
            length: { minimum: 3, maximum: 255 },
            uniqueness: { scope: :user_id, case_sensitive: false }

  # This token will only be different than nil
  # when it is newly created, not when fetched
  # from the database
  attr_reader :token

  def initialize(*params)
    super(*params)

    # If there is no digest (we have a new instance)
    # generate a new random token
    self.token = SecureRandom.urlsafe_base64(32) unless token_digest
  end

  # Setting the token also creates the digest
  def token=(token)
    @token = token
    self.token_digest = ApiToken.digest(token)
  end

  # Creates digest and tries to find it in the database.
  # If the token is empty, returns nil
  def self.find_token(token)
    return nil if token.blank?

    ApiToken.find_by(token_digest: ApiToken.digest(token))
  end

  # Use class method to easily change digest function
  def self.digest(token)
    Digest::SHA256.base64digest(token)
  end
end
