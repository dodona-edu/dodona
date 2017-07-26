require File.dirname(__FILE__) + '/../helpers/stub_helper.rb'
using StubHelper

FactoryGirl.define do
  factory :judge do
    name { |n| "python-#{n}" }
    image { |n| "dodona-python#{n}" }
    path { |n| "python-#{n}.git" }
    remote { |n| "git@github.ugent.be:dodona/judge-python#{n}.git" }

    renderer FeedbackTableRenderer
    runner SubmissionRunner

    trait :git_stubbed do
      after :build do |judge|
        stub_git(judge)
      end
    end
  end
end
