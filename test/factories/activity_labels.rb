# == Schema Information
#
# Table name: activity_labels
#
#  id          :bigint           not null, primary key
#  activity_id :integer          not null
#  label_id    :bigint           not null
#

FactoryBot.define do
  factory :activity_label do
    activity
    label
  end
end
