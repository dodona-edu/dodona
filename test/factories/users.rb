FactoryGirl.define do
  factory :user do
    first_name Faker::Name.first_name
    last_name Faker::Name.last_name
    username { Faker::Internet.unique.user_name(5..8) }
    ugent_id Faker::Number.number(8).to_s
    email { "#{first_name}.#{last_name}@UGent.BE" }
    permission :student
  end
end
