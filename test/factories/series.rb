FactoryGirl.define do
  factory :series do
    sequence(:name) { |n| "Series #{n}" }
    description Faker::DrWho.quote
    visibility :open
    deadline Time.zone.today + 1.day
    course

    trait :hidden do
      visibility :hidden
    end

    transient do
      exercise_count 0
    end

    after :create do |series, e|
      create_list(:exercise, e.exercise_count, series: [series])
    end

    trait :with_submissions do
      after :create do |series|
        repositories = create_list(:repository, 2, :git_stubbed)
        users = create_list(:user, 5, courses: [series.course])

        10.times do
          create(:exercise,
                 repository: repositories.sample,
                 series: [series])
        end

        30.times do
          create(:submission,
                 exercise: series.exercises.sample,
                 user: users.sample)
        end
      end
    end

  end
end
