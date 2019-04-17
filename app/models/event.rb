class Event < ApplicationRecord
  enum event_type: %i[rejudge]
  belongs_to :user

  validates :event_type, presence: true
  validates :message, presence: true

  default_scope {order(id: :desc)}
end
