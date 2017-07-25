FactoryGirl.define do
  factory :course do
    name "#{Faker::Hacker.adjective.titlecase}"
    description Faker::Hacker.say_something_smart
    open true

    transient do
      year Time.zone.today.year
    end
    year { "#{this_year}-#{this_year + 1}" }

    transient do
      series_count 1
      users_count 1
    end

    after(:create) do |course, evaluator|
      create_list(:user, evaluator.users_count, user: user)
      create_list(:series, evaluator.series_count, series: series)
    end
  end
end
