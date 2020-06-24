class Provider < ApplicationRecord
  belongs_to :institution, inverse_of: :providers
end
