# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  username   :string(255)
#  ugent_id   :string(255)
#  first_name :string(255)
#  last_name  :string(255)
#  email      :string(255)
#  permission :integer          default("student")
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  lang       :string(255)      default("nl")
#  token      :string(255)
#  time_zone  :string(255)      default("Brussels")
#

FactoryGirl.define do
  factory :user, aliases: [:student] do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.unique.user_name(5..8) }
    ugent_id Faker::Number.number(8).to_s
    email { "#{first_name}.#{last_name}@UGent.BE".downcase }
    permission :student
  end

  factory :zeus, parent: :user do
    permission :zeus
  end

  factory :staff, parent: :user do
    permission :staff
  end
end
