FactoryGirl.define do
  factory :submission, aliases: [:correct_submission] do
    status :correct
    summary 'Correct answer'
    accepted true

    code { Faker::Lorem.paragraph }
    result '{}'

    user
    exercise

    initialize_with { new(attributes) }

    transient do
      evaluation_stubbed true
    end

    after(:build) do |submission, e|
      submission.stubs(:evaluate_delayed) if e.evaluation_stubbed
    end
  end

  factory :wrong_submission, parent: :submission do
    status :wrong
    summary 'You used the wrong programming language.'
    accepted false
  end
end
