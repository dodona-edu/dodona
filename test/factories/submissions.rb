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
    evaluate { true }
    skip_rate_limit_check { true }
    result { nil }

    transient do
      status { nil }
      summary { nil }
    end

    # When created, the submission ia queued and the status,
    # result and summary are overwritten.
    # Overwrite them again if explicitly given
    after(:create) do |submission, e|
      attrs = {}
      attrs[:result] = e.result if e.result
      attrs[:status] = e.status if e.status
      attrs[:summary] = e.summary if e.summary
      submission.update(attrs)
    end

    user
    association :activity, factory: :exercise
    exercise { activity }

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
