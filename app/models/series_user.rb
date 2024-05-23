class SeriesUser < ApplicationRecord
  belongs_to :user
  belongs_to :series
  validates :user_id, uniqueness: { scope: :series_id }
end
