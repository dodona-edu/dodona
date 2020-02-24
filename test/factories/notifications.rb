# == Schema Information
#
# Table name: notifications
#
#  id              :bigint           not null, primary key
#  message         :string(255)      not null
#  read            :boolean          default("0"), not null
#  user_id         :integer          not null
#  notifiable_type :string(255)
#  notifiable_id   :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

FactoryBot.define do
  factory :notification do
    message { Faker::Lorem.words(number: 5) }
    notifiable { |n| n.association(:export) }
    user
  end
end
