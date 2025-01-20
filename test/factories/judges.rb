# == Schema Information
#
# Table name: judges
#
#  id           :integer          not null, primary key
#  clone_status :integer          default("queued"), not null
#  deprecated   :boolean          default(FALSE), not null
#  image        :string(255)
#  name         :string(255)
#  path         :string(255)
#  remote       :string(255)
#  renderer     :string(255)      not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require "#{File.dirname(__FILE__)}/../testhelpers/stub_helper.rb"
using StubHelper

FactoryBot.define do
  factory :judge do
    sequence(:name) { |n| "python-#{n}" }
    sequence(:image) { |n| "dodona-python#{n}" }
    sequence(:remote) { |n| "git@github.com:dodona-edu/judge-python#{n}.git" }

    renderer { FeedbackTableRenderer }

    trait :git_stubbed do
      sequence(:path) { |n| "python-#{n}.git" }

      after :build do |judge|
        stub_git(judge)
        judge.stubs(:config).returns({})
      end
    end
  end
end
