FactoryBot.define do
  factory :announcement do
    text_nl { Faker::Lorem.paragraph }
    text_en { Faker::Lorem.paragraph }
    user_group { :all_users }
    style { :primary }
  end
end
