# == Schema Information
#
# Table name: exercise_labels
#
#  id          :bigint(8)        not null, primary key
#  exercise_id :integer          not null
#  label_id    :bigint(8)        not null
#

FactoryBot.define do
  factory :exercise_label do
    exercise
    label
  end
end
