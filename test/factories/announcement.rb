FactoryBot.define do
  factory :announcement do
    text { Faker::Lorem.paragraph }
    user_group { :all_users }
    style { :primary }
  end
end
