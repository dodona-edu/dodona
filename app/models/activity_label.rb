# == Schema Information
#
# Table name: activity_labels
#
#  id          :bigint           not null, primary key
#  activity_id :integer          not null
#  label_id    :bigint           not null
#

class ActivityLabel < ApplicationRecord
  belongs_to :activity
  belongs_to :label
end
