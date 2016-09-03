# == Schema Information
#
# Table name: series
#
#  id          :integer          not null, primary key
#  course_id   :integer
#  name        :string(255)
#  description :text(65535)
#  visibility  :integer
#  order       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Series < ApplicationRecord
  belongs_to :course
end
