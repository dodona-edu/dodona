FactoryGirl.define do
  factory :submission do
    summary 'Correct answer'

    code { Faker::Lorem.paragraph }
    result '{}'

    user
    exercise

    initialize_with { new(attributes) }

    trait :correct do
      after(:create) do |submission|
        submission.update(
          status: 'correct',
          summary: 'Good job!',
          accepted: true
        )
      end
    end

    trait :wrong do
      after(:create) do |submission|
        submission.update(
          status: 'wrong',
          summary: 'You used the wrong programming language',
          accepted: false
        )
      end
    end

    factory :wrong_submission, traits: [:wrong]
    factory :correct_submission, traits: [:correct]
  end
end
