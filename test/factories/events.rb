FactoryBot.define do
  factory :event do
    event_type Event.event_types.keys.sample
    user
    message {Faker::Lorem.words 5}
  end
end
