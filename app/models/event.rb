# == Schema Information
#
# Table name: events
#
#  id         :bigint           not null, primary key
#  event_type :integer          not null
#  user_id    :integer
#  message    :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Event < ApplicationRecord
  enum event_type: { rejudge: 0, permission_change: 1, exercise_repository: 2, error: 3, no_auth_id_sign_in: 4 }
  belongs_to :user, optional: true

  validates :event_type, presence: true
  validates :message, presence: true

  scope :by_type, ->(type) { where(event_type: type.in?(event_types) ? type : -1) }
  default_scope { order(id: :desc) }
end
