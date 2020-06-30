# == Schema Information
#
# Table name: institutions
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  short_name :string(255)
#  logo       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryBot.define do
  factory :institution, class: Institution do
    name { Faker::University.unique.name }
    short_name { name.gsub(/\s+/, '') }
    logo { 'logo.png' }
  end
end
