class Provider < ApplicationRecord
  belongs_to :institution, inverse_of: :providers

  has_many :identities, inverse_of: :provider, dependent: :destroy
end
