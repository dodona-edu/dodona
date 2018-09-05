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
#

FactoryBot.define do
  factory :submission do
    code { Faker::Lorem.paragraph }

    transient do
      status { nil }
      result { nil }
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

    trait :within_course do
      series
    end

    factory :wrong_submission, traits: [:wrong]
    factory :correct_submission, traits: [:correct]
  end
end
