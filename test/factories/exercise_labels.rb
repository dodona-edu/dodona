# == Schema Information
#
# Table name: exercise_labels
#
#  id          :bigint           not null, primary key
#  exercise_id :integer          not null
#  label_id    :bigint           not null
#

FactoryBot.define do
  factory :exercise_label do
    exercise
    label
  end
end
