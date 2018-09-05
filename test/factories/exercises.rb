# == Schema Information
#
# Table name: exercises
#
#  id                   :integer          not null, primary key
#  name_nl              :string(255)
#  name_en              :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  path                 :string(255)
#  description_format   :string(255)
#  programming_language :string(255)
#  repository_id        :integer
#  judge_id             :integer
#  status               :integer          default("ok")
#  access               :integer          default("public")
#

FactoryBot.define do
  factory :exercise do
    sequence(:name_nl) { |n| name || "Oefening #{n}" }
    sequence(:name_en) { |n| name || "Exercise #{n}" }

    access { 'public' }
    status { 'ok' }

    sequence(:path) { |n| "exercise#{n}" }

    association :repository, factory: %i[repository git_stubbed]
    judge { repository.judge }

    transient do
      name { nil }
      description_html_stubbed { nil }

      submission_count { 0 }
      submission_users do
        create_list :user, 5 if submission_count.positive?
      end
    end

    after :create do |exercise, e|
      e.submission_count.times do
        create :submission,
               exercise: exercise,
               user: e.submission_users.sample
      end
      if e.description_html_stubbed
        exercise.description_format = 'html'
        exercise.stubs(:description_localized).returns(e.description_html_stubbed)
      end
    end

    trait :nameless do
      name_nl { nil }
      name_en { nil }
    end

    trait :config_stubbed do
      after :create do |exercise|
        exercise.stubs(:config)
                .returns({ 'evaluation': {} }.stringify_keys)
      end
    end

    trait :description_html do
      description_format { 'html' }
      after :create do |exercise|
        exercise.stubs(:description_localized).returns <<~EOS
          <h2 id="los-deze-oefening-op">Los deze oefening op</h2>
          <p><img src="media/img.jpg" alt="media-afbeelding"/>
          <a href="https://google.com">LMGTFY</a>
          <a href="../123455/">Volgende oefening</a></p>
        EOS
      end
    end

    trait :description_md do
      description_format { 'md' }
      after :create do |exercise|
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
