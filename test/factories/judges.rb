require File.dirname(__FILE__) + '/../helpers/stub_helper.rb'
using StubHelper

FactoryGirl.define do
  factory :judge do
    sequence(:name) { |n| "python-#{n}" }
    sequence(:image) { |n| "dodona-python#{n}" }
    sequence(:remote) { |n| "git@github.ugent.be:dodona/judge-python#{n}.git" }

    renderer FeedbackTableRenderer
    runner SubmissionRunner

    trait :git_stubbed do
      sequence(:path) { |n| "python-#{n}.git" }

      after :build do |judge|
        stub_git(judge)
      end
    end
  end
end
