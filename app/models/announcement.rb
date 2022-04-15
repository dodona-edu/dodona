# == Schema Information
#
# Table name: announcements
#
#  id                  :bigint           not null, primary key
#  text                :text(65535)      not null
#  start_delivering_at :datetime
#  stop_delivering_at  :datetime
#  user_group          :integer          not null
#  institution_id      :integer
#  style               :integer          not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class Announcement < ApplicationRecord
  has_many :announcement_views, dependent: :destroy
  enum user_group: { all_users: 0, students: 1, staff: 2, zeus: 3 }
  enum style: { primary: 0, secondary: 1, success: 2, danger: 3, warning: 4, info: 5 }

  validates :text, presence: true
  validates :user_group, presence: true
  validates :style, presence: true

  scope :is_active, lambda {
    where("(start_delivering_at < ? OR start_delivering_at IS NULL)
				AND (stop_delivering_at > ? OR stop_delivering_at IS NULL)", Time.current, Time.current)
  }

  scope :unread_by, lambda { |current_user|
    joins("LEFT JOIN announcement_views ON
				announcement_views.announcement_id = announcements.id AND
				announcement_views.user_id = #{sanitize_sql_for_conditions(current_user.id)}")
      .where('announcement_views.announcement_id IS NULL AND announcement_views.user_id IS NULL')
  }

  default_scope { order('start_delivering_at ASC') }

end
