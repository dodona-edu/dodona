# == Schema Information
#
# Table name: identities
#
#  id                           :bigint           not null, primary key
#  identifier                   :string(255)      not null
#  identifier_based_on_email    :boolean          default(FALSE), not null
#  identifier_based_on_username :boolean          default(FALSE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  provider_id                  :bigint           not null
#  user_id                      :integer          not null
#
# Indexes
#
#  fk_rails_5373344100                             (user_id)
#  index_identities_on_provider_id_and_identifier  (provider_id,identifier) UNIQUE
#  index_identities_on_provider_id_and_user_id     (provider_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
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
