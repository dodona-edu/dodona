# == Schema Information
#
# Table name: announcements
#
#  id                  :bigint           not null, primary key
#  text_nl             :text(65535)      not null
#  text_en             :text(65535)      not null
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
  enum style: { primary: 0, success: 1, danger: 2, warning: 3, info: 4 }

  validates :text_nl, presence: true
  validates :text_en, presence: true
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

  def text
    send("text_#{I18n.locale}")
  end

  def active
    (start_delivering_at.nil? || start_delivering_at < Time.current) && (stop_delivering_at.nil? || stop_delivering_at > Time.current)
  end

  def unread_by(user)
    announcement_views.find(user: user).nil?
  end

  def number_of_reads
    announcement_views.count
  end
end
