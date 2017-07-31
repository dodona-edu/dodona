require File.dirname(__FILE__) + '/../helpers/stub_helper.rb'
using StubHelper

FactoryGirl.define do
  factory :repository do
    name { Faker::Lorem.unique.word }
    remote { "git@github.ugent.be:dodona/#{name}.git" }
    association :judge, factory: [:judge, :git_stubbed]

    trait :git_stubbed do
      path { "#{name}.git" }

      after :build do |repository|
        stub_git(repository)
      end
    end
  end
end
