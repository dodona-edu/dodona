FactoryGirl.define do
  factory :course do
    name { "#{Faker::Hacker.adjective.titlecase} Programming" }
    description { Faker::Hacker.say_something_smart }
    open true

    transient do
      start_year Time.zone.today.year
    end

    year { "#{start_year}-#{start_year + 1}" }
  end
end
