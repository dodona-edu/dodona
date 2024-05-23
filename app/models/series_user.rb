# == Schema Information
#
# Table name: series_users
#
#  id         :bigint           not null, primary key
#  user_id    :integer
#  series_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SeriesUser < ApplicationRecord
  belongs_to :user
  belongs_to :series
  validates :user_id, uniqueness: { scope: :series_id }
end
