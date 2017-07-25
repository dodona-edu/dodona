require 'helpers/stub_helper'

FactoryGirl.define do
  factory :judge do
    name 'pythia'
    image 'dodona-anconda3'
    path 'placeholder'
    remote 'placeholder'

    renderer FeedbackTableRenderer
    runner SubmissionRunner

    trait :git_stubbed do
      after :build do |judge|
        StubHelper.stub_git(judge)
      end
    end
  end
end
