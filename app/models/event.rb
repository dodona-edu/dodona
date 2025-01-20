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

class Event < ApplicationRecord
  include Filterable
  enum :event_type, { rejudge: 0, permission_change: 1, exercise_repository: 2, error: 3, other: 4 }
  belongs_to :user, optional: true

  validates :event_type, presence: true
  validates :message, presence: true

  filterable_by :event_type, is_enum: true
  default_scope { order(id: :desc) }
end
