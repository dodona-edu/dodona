FactoryGirl.define do
  factory :course do
    name { "#{Faker::Hacker.adjective.titlecase} Programming" }
    description { Faker::Hacker.say_something_smart }
    open true

    transient do
      series_count 0
      exercises_per_series 0
      start_year Time.zone.today.year
    end

    year { "#{start_year}-#{start_year + 1}" }

    trait :with_series_and_exercises do
      series_count 4
      exercises_per_series 5
    end

    after :create do |course, e|
      create_list :series, e.series_count,
                  course: course,
                  exercise_count: e.exercises_per_series
    end
  end
end
