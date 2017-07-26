
FactoryGirl.define do
  factory :submission do
    status :correct
    summary "Correct answer"
    accepted true

    code ''
    result 'ok'

    user
    exercise

    initialize_with { new(attributes) }
  end
end
