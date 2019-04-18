class Event < ApplicationRecord
  enum event_type: %i[rejudge permission_change exercise_repository error]
  belongs_to :user, optional: true

  validates :event_type, presence: true
  validates :message, presence: true

  default_scope {order(id: :desc)}
end
