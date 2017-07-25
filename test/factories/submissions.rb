
FactoryGirl.define do
  factory :submission do

    status :correct
    summary "Correct answer"
    accepted true

    user
    exercise
  end
end
