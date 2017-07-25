
FactoryGirl.define do
  factory :repository do
    name 'my_repo'
    remote 'placeholder'
    association :judge, factory: [:judge, :git_stubbed]

    trait :git_stubbed do
      after :build do |repository|
        stub_git(repository)
      end
    end
  end
end
