# == Schema Information
#
# Table name: activity_labels
#
#  id          :bigint           not null, primary key
#  activity_id :integer          not null
#  label_id    :bigint           not null
#
# Indexes
#
#  fk_rails_0510a660e5                                (label_id)
#  index_activity_labels_on_activity_id_and_label_id  (activity_id,label_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id)
#  fk_rails_...  (label_id => labels.id)
#

FactoryBot.define do
  factory :activity_label do
    activity
    label
  end
end
