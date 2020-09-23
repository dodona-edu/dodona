# == Schema Information
#
# Table name: activities
#
#  id                      :integer          not null, primary key
#  name_nl                 :string(255)
#  name_en                 :string(255)
#  description_nl_present  :boolean
#  description_en_present  :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  path                    :string(255)
#  description_format      :string(255)
#  repository_id           :integer
#  judge_id                :integer
#  status                  :integer          default("ok")
#  access                  :integer          default("public"), not null
#  programming_language_id :bigint
#  search                  :string(4096)
#  access_token            :string(16)       not null
#  repository_token        :string(64)       not null
#  allow_unsafe            :boolean          default(FALSE), not null
#  type                    :string(255)      default("Exercise"), not null
#

require "#{File.dirname(__FILE__)}/../testhelpers/stub_helper.rb"
using StubHelper

FactoryBot.define do
  factory :exercise do
    sequence(:name_nl) { |n| name || "Oefening #{n}" }
    sequence(:name_en) { |n| name || "Exercise #{n}" }

    description_nl_present { false }
    description_en_present { false }
    access { 'public' }
    status { 'ok' }
    programming_language

    sequence(:path) { |n| "exercise#{n}" }

    association :repository, factory: %i[repository git_stubbed]
    judge { repository.judge }

    transient do
      name { nil }
      description_html_stubbed { nil }
      description_md_stubbed { nil }

      submission_count { 0 }
      submission_users do
        create_list :user, 5 if submission_count.positive?
      end
    end

    after :create do |exercise, e|
      e.submission_count.times do
        create :submission,
               exercise: exercise,
               course: e.series&.first&.course,
               user: e.submission_users.sample
      end
      if e.description_html_stubbed
        exercise.description_format = 'html'
        stub_status(exercise, 'ok')
        exercise.stubs(:description_localized).returns(e.description_html_stubbed)
      elsif e.description_md_stubbed
        exercise.description_format = 'md'
        stub_status(exercise, 'ok')
        exercise.stubs(:description_localized).returns(e.description_md_stubbed)
      end
    end

    after :build do |exercise|
      exercise.stubs(:merged_config).returns('evaluation' => { 'time_limit' => 1 })
    end

    trait :nameless do
      name_nl { nil }
      name_en { nil }
    end

    trait :config_stubbed do
      after :build do |exercise|
        exercise.stubs(:update_config)
        exercise.stubs(:config)
                .returns({ 'evaluation': {} }.stringify_keys)
      end
    end

    trait :valid do
      config_stubbed
      after :build do |exercise|
        exercise.update(status: :ok)
        stub_status(exercise, 'ok')
      end
    end

    trait :description_html do
      valid
      description_format { 'html' }
      description_en_present { true }
      description_nl_present { true }
      after :build do |exercise|
        exercise.stubs(:description_localized).returns <<~EOS
          <h2 id="los-deze-oefening-op">Los deze oefening op</h2>
          <p><img src="media/img.jpg" alt="media-afbeelding"/>
          <a href="https://google.com">LMGTFY</a>
          <a href="../123455/">Volgende oefening</a></p>
        EOS
      end
    end

    trait :description_md do
      valid
      description_format { 'md' }
      description_en_present { true }
      description_nl_present { true }
      after :build do |exercise|
        exercise.stubs(:description_localized).returns <<~EOS
          ## Los deze oefening op
          ![media-afbeelding](media/img.jpg)
          [LMGTFY](https://google.com)
          [Volgende oefening](../123455/)
        EOS
      end
    end
  end
end
