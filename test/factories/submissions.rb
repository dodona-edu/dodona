
FactoryGirl.define do
  factory :submission do
    status :correct
    summary 'Correct answer'
    accepted true

    code { Faker::Lorem.paragraph }
    result 'ok'

    user
    exercise

    initialize_with { new(attributes) }
  end
end
