# == Schema Information
#
# Table name: repositories
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  remote            :string(255)
#  path              :string(255)
#  judge_id          :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  clone_status      :integer          default("queued"), not null
#  featured          :boolean          default(FALSE)
#  reprocess_queued  :boolean          default(FALSE)
#  reprocess_running :boolean          default(FALSE)
#

require "#{File.dirname(__FILE__)}/../testhelpers/stub_helper.rb"
using StubHelper

FactoryBot.define do
  factory :repository do
    name { Faker::Lorem.word + Faker::Number.unique.number(digits: 8).to_s }
    remote { "git@github.com:dodona-edu/#{name}.git" }
    judge { Judge.find(1) } # load python judge fixture

    trait :generated_judge do
      judge factory: %i[judge git_stubbed]
    end

    trait :git_stubbed do
      path { "#{name}.git" }

      after :build do |repository|
        stub_git(repository)
        repository.stubs(:process_activities)
      end
    end
  end
end
