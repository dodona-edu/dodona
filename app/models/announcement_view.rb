# == Schema Information
#
# Table name: announcement_views
#
#  id              :bigint           not null, primary key
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  announcement_id :bigint           not null
#  user_id         :integer          not null
#
class AnnouncementView < ApplicationRecord
  belongs_to :announcement
  belongs_to :user

  validates :user_id, uniqueness: { scope: :announcement_id }
end
