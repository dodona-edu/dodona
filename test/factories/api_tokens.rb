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

FactoryGirl.define do
  factory :api_token do
    description { Faker::Lorem.unique.sentence }
    user
  end
end
