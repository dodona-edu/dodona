# == Schema Information
#
# Table name: api_tokens
#
#  id           :bigint           not null, primary key
#  description  :string(255)
#  token_digest :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint
#
# Indexes
#
#  index_api_tokens_on_token_digest             (token_digest)
#  index_api_tokens_on_user_id                  (user_id)
#  index_api_tokens_on_user_id_and_description  (user_id,description) UNIQUE
#

FactoryBot.define do
  factory :api_token do
    description { Faker::Lorem.unique.sentence }
    user { User.find(3) } # load student fixture
  end
end
