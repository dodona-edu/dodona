# == Schema Information
#
# Table name: repositories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  remote     :string(255)
#  path       :string(255)
#  judge_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require File.dirname(__FILE__) + '/../helpers/stub_helper.rb'
using StubHelper

FactoryGirl.define do
  factory :repository do
    name { Faker::Lorem.unique.word }
    remote { "git@github.ugent.be:dodona/#{name}.git" }
    association :judge, factory: %i[judge git_stubbed]

    trait :git_stubbed do
      path { "#{name}.git" }

      after :build do |repository|
        stub_git(repository)
      end
    end
  end
end
