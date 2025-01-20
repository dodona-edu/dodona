# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  accepted    :boolean          default(FALSE)
#  annotated   :boolean          default(FALSE), not null
#  fs_key      :string(24)
#  number      :integer
#  status      :integer
#  summary     :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  course_id   :integer
#  exercise_id :integer
#  series_id   :integer
#  user_id     :integer
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
      user
    end

    trait :generated_exercise do
      exercise
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
