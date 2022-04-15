# == Schema Information
#
# Table name: announcement_views
#
#  id              :bigint           not null, primary key
#  user_id         :integer
#  announcement_id :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class AnnouncementView < ApplicationRecord
  belongs_to :announcement
  belongs_to :user

  validates :user_id, uniqueness: { scope: :announcement_id }
end
