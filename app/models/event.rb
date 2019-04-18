class Event < ApplicationRecord
  enum event_type: %i[rejudge permission_change exercise_repository error]
  belongs_to :user, optional: true

  validates :event_type, presence: true
  validates :message, presence: true

  scope :by_type, ->(type) {where(event_type: type.in?(event_types) ? type : -1)}
  default_scope {order(id: :desc)}
end
