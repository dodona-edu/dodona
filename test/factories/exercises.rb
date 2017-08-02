FactoryGirl.define do
  factory :exercise do
    sequence(:name_nl) { |n| "Oefening #{n}" }
    sequence(:name_en) { |n| "Exercise #{n}" }
    visibility 'open'
    status :ok

    sequence(:path) { |n| "exercise#{n}" }

    association :repository, factory: %i[repository git_stubbed]
    judge { repository.judge }

    trait :config_stubbed do
      after :create do |exercise|
        exercise.stubs(:config)
                .returns({ 'evaluation': {} }.stringify_keys)
      end
    end
  end
end
