# == Schema Information
#
# Table name: series_memberships
#
#  id              :integer          not null, primary key
#  series_id       :integer
#  exercise_id     :integer
#  order           :integer          default(999)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class SeriesMembership < ApplicationRecord
  belongs_to :series
  belongs_to :exercise

  delegate :course, to: :series

  default_scope {order(order: :asc)}

  validates :series_id, uniqueness: {scope: :exercise_id}
end
