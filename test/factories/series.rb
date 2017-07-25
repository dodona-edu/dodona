FactoryGirl.define do
  factory :series do
    sequence(:name) { |n| "Series #{n}" }
    description Faker::DrWho.quote
    visibility :open
    deadline Time.zone.today + 1.day
    course
  end
end
