# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint(8)        not null, primary key
#  user_id      :bigint(8)
#  token_digest :string(255)
#  description  :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryBot.define do
  factory :api_token do
    description { Faker::Lorem.unique.sentence }
    user
  end
end
