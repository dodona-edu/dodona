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
FactoryBot.define do
  factory :identity do
    provider
    user
    identifier { user.username || SecureRandom.uuid }

    after :create do |identity|
      identity.user.identities << identity
    end
  end
end
