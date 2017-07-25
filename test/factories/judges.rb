require 'helpers/stub_helper'
using StubHelper

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
        stub_git(judge)
      end
    end
  end
end
