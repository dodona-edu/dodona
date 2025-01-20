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
# Indexes
#
#  index_announcement_views_on_announcement_id              (announcement_id)
#  index_announcement_views_on_user_id                      (user_id)
#  index_announcement_views_on_user_id_and_announcement_id  (user_id,announcement_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (announcement_id => announcements.id)
#  fk_rails_...  (user_id => users.id)
#
class AnnouncementView < ApplicationRecord
  belongs_to :announcement
  belongs_to :user

  validates :user_id, uniqueness: { scope: :announcement_id }
end
