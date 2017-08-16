FactoryGirl.define do
  factory :exercise do
    sequence(:name_nl) { |n| name || "Oefening #{n}" }
    sequence(:name_en) { |n| name || "Exercise #{n}" }

    visibility 'open'
    status 'ok'

    sequence(:path) { |n| "exercise#{n}" }

    association :repository, factory: %i[repository git_stubbed]
    judge { repository.judge }

    transient do
      name nil

      submission_count 0
      submission_users do
        create_list :user, 5 if submission_count.positive?
      end
    end

    after :create do |exercise, e|
      e.submission_count.times do
        create :submission,
               exercise: exercise,
               user: e.submission_users.sample
      end
    end

    trait :nameless do
      name_nl nil
      name_en nil
    end

    trait :config_stubbed do
      after :create do |exercise|
        exercise.stubs(:config)
                .returns({ 'evaluation': {} }.stringify_keys)
      end
    end
  end
end
