# == Schema Information
#
# Table name: series_users
#
#  id         :bigint           not null, primary key
#  user_id    :integer
#  series_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :series_user do
    user
    series
  end
end
