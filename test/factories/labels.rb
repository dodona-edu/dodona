# == Schema Information
#
# Table name: labels
#
#  id    :bigint           not null, primary key
#  color :integer          not null
#  name  :string(255)      not null
#
# Indexes
#
#  index_labels_on_name  (name) UNIQUE
#

FactoryBot.define do
  factory :label do
    name { Faker::Lorem.unique.word }
    color { Label.colors.keys.sample }
  end
end
