# == Schema Information
#
# Table name: labels
#
#  id    :bigint           not null, primary key
#  name  :string(255)      not null
#  color :integer          not null
#

FactoryBot.define do
  factory :label do
    name { Faker::Lorem.unique.word }
    color { Label.colors.keys.sample }
  end
end
