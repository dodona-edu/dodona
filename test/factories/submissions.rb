# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  exercise_id :integer
#  user_id     :integer
#  summary     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  status      :integer
#  accepted    :boolean          default(FALSE)
#  course_id   :integer
#  fs_key      :string(24)
#

FactoryBot.define do
  factory :submission do
    code { Faker::Lorem.paragraph }
    evaluate { false }
    skip_rate_limit_check { true }

    user { User.find(3) } # load student user fixture
    exercise { Exercise.find(1) } # load python exercise fixture

    initialize_with { new(attributes) }

    trait :generated_user do
      association :user
    end

    trait :generated_exercise do
      association :exercise
    end

    trait :correct do
      status { 'correct' }
      summary { 'Good job!' }
      accepted { true }
    end

    trait :wrong do
      status { 'wrong' }
      summary { 'You used the wrong programming language' }
      accepted { false }
    end

    trait :within_course do
      course
    end

    factory :wrong_submission, traits: [:wrong]
    factory :correct_submission, traits: [:correct]
    factory :course_submission, traits: [:within_course]

    trait :rate_limited do
      skip_rate_limit_check { false }
    end
  end
end
