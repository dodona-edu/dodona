# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  username       :string(255)
#  ugent_id       :string(255)
#  first_name     :string(255)
#  last_name      :string(255)
#  email          :string(255)
#  permission     :integer          default("student")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  lang           :string(255)      default("nl")
#  token          :string(255)
#  time_zone      :string(255)      default("Brussels")
#  institution_id :bigint(8)
#  search         :string(4096)
#

FactoryBot.define do
  factory :user, aliases: [:student] do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    username { Faker::Internet.unique.user_name(5..32) }
    email { "#{first_name}.#{last_name}.#{username}@UGent.BE".downcase }
    permission { :student }
    institution
  end

  factory :zeus, parent: :user do
    permission { :zeus }
  end

  factory :staff, parent: :user do
    permission { :staff }
  end

  factory :temporary_user, parent: :user do
    username { nil }
    institution { nil }
  end
end
