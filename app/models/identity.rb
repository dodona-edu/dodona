# == Schema Information
#
# Table name: identities
#
#  id          :bigint           not null, primary key
#  identifier  :string(255)      not null
#  provider_id :bigint           not null
#  user_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Identity < ApplicationRecord
  belongs_to :provider, inverse_of: :identities
  belongs_to :user
end
