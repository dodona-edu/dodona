# == Schema Information
#
# Table name: events
#
#  id         :bigint           not null, primary key
#  event_type :integer          not null
#  message    :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
# Indexes
#
#  fk_rails_0cb5590091         (user_id)
#  index_events_on_event_type  (event_type)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#

FactoryBot.define do
  factory :event do
    event_type { Event.event_types.keys.sample }
    user { User.find(2) } # load student fixture
    message { Faker::Lorem.words(number: 5) }
  end
end
