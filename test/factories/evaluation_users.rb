# == Schema Information
#
# Table name: evaluation_users
#
#  id            :bigint           not null, primary key
#  evaluation_id :bigint
#  user_id       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
FactoryBot.define do
  factory :evaluation_user do
    evaluation
    user
  end
end
