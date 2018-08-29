FactoryBot.define do
  factory :tag do
    name { Faker::Lorem.unique.word }
    color { Tag.colors.keys.sample }
  end
end
