FactoryGirl.define do
  factory :exercise do
    sequence(:name_nl) { |n| name || "Oefening #{n}" }
    sequence(:name_en) { |n| name || "Exercise #{n}" }

    visibility 'open'
    status 'ok'

    sequence(:path) { |n| "exercise#{n}" }

    association :repository, factory: %i[repository git_stubbed]
    judge { repository.judge }

    transient do
      name nil

      submission_count 0
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
    end

    trait :nameless do
      name_nl nil
      name_en nil
    end

    trait :config_stubbed do
      after :create do |exercise|
        exercise.stubs(:config)
                .returns({ 'evaluation': {} }.stringify_keys)
      end
    end

    trait :description_html do
      description_format 'html'
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
      description_format 'md'
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
