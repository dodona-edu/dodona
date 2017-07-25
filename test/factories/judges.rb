require 'mocha/mini_test'

FactoryGirl.define do
  factory :judge do
    name 'pythia'
    image 'lol'
    path 'kek'

    trait :git_stubbed do
      after :build do |judge|
        judge.stubs(:repo_is_accessible).returns(true)
        judge.stubs(:clone_repo)
      end
    end
  end
end
