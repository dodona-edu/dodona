class Identity < ApplicationRecord
  belongs_to :provider, inverse_of: :identities
  belongs_to :user
end
