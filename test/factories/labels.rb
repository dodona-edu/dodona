FactoryBot.define do
  factory :label do
    name { Faker::Lorem.unique.word }
    color { Label.colors.keys.sample }
  end
end
